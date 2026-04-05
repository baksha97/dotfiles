import argparse
import asyncio
import datetime
import json
import os
import re
import shutil
import signal
import socket
import socketserver
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field, asdict
from http.server import SimpleHTTPRequestHandler
from pathlib import Path
from typing import Dict, List, Optional

import yaml

# Regex to find GitHub Expressions: ${{ ... }}
EXPRESSION_RE = re.compile(r"\$\{\{\s*(.*?)\s*\}\}")

@dataclass
class Task:
    id: str
    name: str
    command: str
    dir: str = "."
    env: Dict[str, str] = field(default_factory=dict)
    status: str = "QUEUED"
    reason: str = "Pending"
    log_file: Optional[str] = None
    started_at: Optional[str] = None
    ended_at: Optional[str] = None
    order: int = 0

class DashboardHandler(SimpleHTTPRequestHandler):
    runner = None
    def do_POST(self):
        if self.path == '/cancel':
            self.send_response(200); self.end_headers(); self.wfile.write(b"Cancelled"); self.wfile.flush()
            if self.runner: self.runner.cancel()
        else: self.send_error(404)

class AsyncRunner:
    def __init__(self, name: str, tasks: List[Task], port: int = 8080, logs_dir: str = "build/logs"):
        self.name = name
        self.tasks = tasks
        self.port = port
        self.logs_root = Path(logs_dir) / datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        self.logs_root.mkdir(parents=True, exist_ok=True)
        self.is_done = False; self.failures = 0
        self.start_time = datetime.datetime.now(datetime.timezone.utc).isoformat()
        self._cancel_event = asyncio.Event(); self._processes = []

    def get_git_info(self):
        def run_git(args):
            try: return subprocess.check_output(["git"] + args, stderr=subprocess.DEVNULL).decode().strip()
            except: return "N/A"
        branch = run_git(["branch", "--show-current"])
        sha = run_git(["rev-parse", "--short", "HEAD"])
        upstream = run_git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"])
        if upstream == "N/A": upstream = "origin/main"
        base = run_git(["merge-base", upstream, "HEAD"])
        return branch, base, sha

    def write_status(self):
        branch, base, sha = self.get_git_info()
        data = {
            "skill_name": self.name, "started_at": self.start_time, "done": self.is_done, "failures": self.failures,
            "git_branch": branch, "git_base": base, "git_sha": sha,
            "sys_info": f"{os.uname().sysname} {os.uname().nodename} {os.uname().release} {os.uname().machine}",
            "checks": {t.id: {
                "name": t.name, "status": t.status, "reason": t.reason, "log": t.log_file,
                "started_at": t.started_at, "ended_at": t.ended_at, "order": t.order
            } for t in self.tasks}
        }
        if self.is_done: data["ended_at"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        with open(self.logs_root / "status.json", "w") as f: json.dump(data, f, indent=2)

    def cancel(self):
        self._cancel_event.set()
        for p in self._processes:
            try: os.killpg(os.getpgid(p.pid), signal.SIGTERM)
            except: pass

    async def run_task(self, task: Task):
        if self._cancel_event.is_set(): return
        task.status = "RUNNING"; task.started_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
        task.log_file = f"{task.id}.log"; self.write_status()
        log_path = self.logs_root / task.log_file
        try:
            env = os.environ.copy(); env.update(task.env)
            process = await asyncio.create_subprocess_shell(
                task.command, stdout=open(log_path, "w"), stderr=subprocess.STDOUT,
                cwd=task.dir, env=env, preexec_fn=os.setsid
            )
            self._processes.append(process)
            await process.wait()
            if process.returncode == 0:
                task.status = "PASS"; task.reason = "Completed successfully"
            else:
                task.status = "FAIL"; task.reason = f"Failed with exit code {process.returncode}"; self.failures += 1
        except Exception as e:
            task.status = "FAIL"; task.reason = str(e); self.failures += 1
        task.ended_at = datetime.datetime.now(datetime.timezone.utc).isoformat(); self.write_status()

    def start_dashboard(self):
        lib_dir = Path(__file__).parent
        with open(lib_dir / "dashboard.html", "r") as f:
            html = f.read().replace("{{ skill_name }}", self.name)
        with open(self.logs_root / "dashboard.html", "w") as f: f.write(html)
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s: s.bind(('', self.port))
        except OSError:
            subprocess.run(["fuser", "-k", f"{self.port}/tcp"], stderr=subprocess.DEVNULL); time.sleep(1)
        DashboardHandler.runner = self
        server = socketserver.TCPServer(("", self.port), DashboardHandler)
        server.allow_reuse_address = True
        threading.Thread(target=lambda: (os.chdir(self.logs_root), server.serve_forever()), daemon=True).start()
        print(f"[runner] Dashboard opened: http://localhost:{self.port}/dashboard.html")
        subprocess.run(["open", f"http://localhost:{self.port}/dashboard.html"], stderr=subprocess.DEVNULL)

    async def execute(self, parallel=False):
        if parallel: await asyncio.gather(*(self.run_task(t) for t in self.tasks))
        else:
            for t in self.tasks:
                await self.run_task(t)
                if t.status == "FAIL" and not parallel: break
        self.is_done = True; self.write_status()
        print(f"[runner] Run completed. Failures: {self.failures}")

def resolve_expressions(cmd: str, env_context: Dict[str, str]) -> str:
    def replace_match(match):
        expr = match.group(1).strip()
        if expr.startswith("env."): return env_context.get(expr[4:], "")
        return ""
    return EXPRESSION_RE.sub(replace_match, cmd)

def extract_step_from_workflow(workflow_path: Path, step_ref: str) -> Optional[Dict]:
    """Finds a step by name or ID in a workflow file."""
    if not workflow_path.exists(): return None
    with open(workflow_path, "r") as f:
        data = yaml.safe_load(f)
    
    global_env = data.get("env", {})
    for job_id, job in data.get("jobs", {}).items():
        job_dir = job.get("working-directory", ".")
        job_env = {**global_env, **job.get("env", {})}
        for step in job.get("steps", []):
            if step.get("name") == step_ref or step.get("id") == step_ref:
                return {
                    "command": step.get("run", ""),
                    "dir": step.get("working-directory", job_dir),
                    "env": {**job_env, **step.get("env", {})}
                }
    return None

def main():
    parser = argparse.ArgumentParser(description="Async Task Runner")
    parser.add_argument("--tasks-yaml", type=Path, help="Path to tasks.yaml")
    parser.add_argument("--dashboard", action="store_true", help="Run with dashboard")
    parser.add_argument("--parallel", action="store_true", help="Run tasks in parallel")
    parser.add_argument("--port", type=int, help="Override port")
    parser.add_argument("--logs-dir", default="build/logs", help="Custom logs directory")
    args = parser.parse_args()
    
    if not args.tasks_yaml: parser.print_help(); sys.exit(1)
    
    with open(args.tasks_yaml, "r") as f:
        config = yaml.safe_load(f)
    
    suite_name = config.get("name", "Task Suite")
    port = args.port or config.get("port", 8080)
    workflow_path = Path(config.get("workflow", "")) if config.get("workflow") else None
    
    tasks = []
    for i, t in enumerate(config.get("tasks", [])):
        cmd = t.get("command", "")
        dir_path = t.get("dir", ".")
        env = t.get("env", {})
        
        # If this task references a workflow step, pull data from the workflow
        if workflow_path and t.get("workflow_step"):
            wf_step = extract_step_from_workflow(workflow_path, t["workflow_step"])
            if wf_step:
                # Prioritize YAML values over Workflow values for local overrides
                cmd = cmd or wf_step["command"]
                dir_path = t.get("dir") or wf_step["dir"]
                env = {**wf_step["env"], **env}
                cmd = resolve_expressions(cmd, env)
            else:
                print(f"[runner] Warning: Could not find step '{t['workflow_step']}' in {workflow_path}")
        
        tasks.append(Task(id=t["id"], name=t["name"], command=cmd, dir=dir_path, env=env, order=i))

    if not tasks: print("[runner] No valid tasks found."); sys.exit(0)
    runner = AsyncRunner(suite_name, tasks, port, args.logs_dir)
    if args.dashboard: runner.start_dashboard()
    try: asyncio.run(runner.execute(parallel=args.parallel or args.dashboard))
    except KeyboardInterrupt: runner.cancel(); print("\n[runner] Interrupted by user.")
    if args.dashboard:
        print(f"[runner] Dashboard active at http://localhost:{port}/dashboard.html. Press Ctrl+C to exit.")
        try:
            while True: time.sleep(1)
        except KeyboardInterrupt: pass

if __name__ == "__main__": main()
