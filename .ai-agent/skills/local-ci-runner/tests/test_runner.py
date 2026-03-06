import json
import os
import pytest
import asyncio
import subprocess
from pathlib import Path
from unittest.mock import MagicMock, patch
from async_runner.main import Task, AsyncRunner, parse_workflow, parse_tasks_yaml

# --- Unit Tests ---

def test_parse_workflow_basic(tmp_path):
    workflow_content = """
name: CI
jobs:
  build:
    steps:
      - name: Build
        run: ./gradlew build
      - name: Lint
        run: npm run lint
      - name: Other
        run: echo "skip me"
"""
    p = tmp_path / "workflow.yml"
    p.write_text(workflow_content)
    
    name, tasks = parse_workflow(p)
    assert name == "CI"
    assert len(tasks) == 2
    assert tasks[0].command == "./gradlew build"
    assert tasks[0].name == "Build"
    assert tasks[1].command == "npm run lint"
    assert tasks[1].name == "Lint"

def test_parse_workflow_no_name(tmp_path):
    workflow_content = """
jobs:
  test:
    steps:
      - run: pytest
"""
    p = tmp_path / "workflow.yml"
    p.write_text(workflow_content)
    
    name, tasks = parse_workflow(p)
    assert name == "GitHub Workflow"
    assert len(tasks) == 1
    assert tasks[0].command == "pytest"
    assert tasks[0].name == "pytest"

def test_parse_tasks_yaml_full(tmp_path):
    tasks_content = """
name: System Check
port: 9000
tasks:
  - id: t1
    name: Task 1
    command: ls
    dir: /tmp
    env:
      KEY: VALUE
"""
    p = tmp_path / "tasks.yaml"
    p.write_text(tasks_content)
    
    name, tasks, port = parse_tasks_yaml(p)
    assert name == "System Check"
    assert port == 9000
    assert len(tasks) == 1
    assert tasks[0].id == "t1"
    assert tasks[0].dir == "/tmp"
    assert tasks[0].env == {"KEY": "VALUE"}

def test_parse_workflow_complex(tmp_path):
    workflow_content = """
name: Android Integrity
env:
  GLOBAL_VAR: global
jobs:
  build:
    working-directory: ./Android
    env:
      JOB_VAR: job
    steps:
      - name: Spotless
        run: ./gradlew spotlessApply ${{ env.GLOBAL_VAR }} ${{ env.JOB_VAR }} ${{ secrets.NONE }}
        env:
          STEP_VAR: step
"""
    p = tmp_path / "complex.yml"
    p.write_text(workflow_content)
    
    name, tasks = parse_workflow(p)
    assert name == "Android Integrity"
    assert len(tasks) == 1
    t = tasks[0]
    # Check dir resolution
    assert t.dir == "./Android"
    # Check env inheritance
    assert t.env["GLOBAL_VAR"] == "global"
    assert t.env["JOB_VAR"] == "job"
    assert t.env["STEP_VAR"] == "step"
    # Check expression resolution
    # Should resolve env.GLOBAL_VAR and env.JOB_VAR, and strip secrets.NONE
    assert t.command == "./gradlew spotlessApply global job "

def test_git_info_mocked(tmp_path):
    runner = AsyncRunner("Test", [], logs_dir=str(tmp_path))
    
    with patch("subprocess.check_output") as mock_git:
        def side_effect(args, **kwargs):
            if args[1] == "branch": return b"feat-test\n"
            if args[1] == "rev-parse" and args[2] == "--short": return b"abc1234\n"
            if args[1] == "rev-parse" and "--symbolic-full-name" in args: return b"origin/main\n"
            if args[1] == "merge-base": return b"base-sha\n"
            return b""
        
        mock_git.side_effect = side_effect
        branch, base, sha = runner.get_git_info()
        
        assert branch == "feat-test"
        assert sha == "abc1234"
        assert base == "base-sha"

# --- Integration Tests ---

@pytest.mark.asyncio
async def test_runner_sequential_failure(tmp_path):
    # Sequential run should stop at first failure
    tasks = [
        Task(id="t1", name="Pass", command="echo 'hi'", order=0),
        Task(id="t2", name="Fail", command="exit 1", order=1),
        Task(id="t3", name="Skip", command="echo 'wont run'", order=2),
    ]
    runner = AsyncRunner("Fail Test", tasks, logs_dir=str(tmp_path))
    await runner.execute(parallel=False)
    
    assert tasks[0].status == "PASS"
    assert tasks[1].status == "FAIL"
    assert tasks[2].status == "QUEUED"
    assert runner.failures == 1

@pytest.mark.asyncio
async def test_runner_parallel_success(tmp_path):
    tasks = [
        Task(id="t1", name="P1", command="sleep 0.1 && echo '1'", order=0),
        Task(id="t2", name="P2", command="sleep 0.1 && echo '2'", order=1),
    ]
    runner = AsyncRunner("Parallel Test", tasks, logs_dir=str(tmp_path))
    
    start = asyncio.get_event_loop().time()
    await runner.execute(parallel=True)
    end = asyncio.get_event_loop().time()
    
    assert tasks[0].status == "PASS"
    assert tasks[1].status == "PASS"
    # Should take ~0.1s total if parallel, not 0.2s
    assert end - start < 0.18

@pytest.mark.asyncio
async def test_runner_cancellation(tmp_path):
    # A long running task that we will cancel
    task = Task(id="long", name="Long", command="sleep 10", order=0)
    runner = AsyncRunner("Cancel Test", [task], logs_dir=str(tmp_path))
    
    run_task = asyncio.create_task(runner.execute())
    
    # Wait a bit for it to start
    await asyncio.sleep(0.2)
    assert task.status == "RUNNING"
    
    # Cancel it
    runner.cancel()
    await run_task
    
    assert task.status == "FAIL"
    assert "code" in task.reason or "signal" in task.reason or "Cancel" in task.reason

@pytest.mark.asyncio
async def test_status_json_persistence(tmp_path):
    task = Task(id="test", name="Test", command="echo 'hello'", order=0)
    runner = AsyncRunner("Persist Test", [task], logs_dir=str(tmp_path))
    await runner.execute()
    
    status_file = runner.logs_root / "status.json"
    assert status_file.exists()
    
    with open(status_file, "r") as f:
        data = json.load(f)
        assert data["skill_name"] == "Persist Test"
        assert data["checks"]["test"]["status"] == "PASS"
        assert data["done"] is True
        assert "sys_info" in data
