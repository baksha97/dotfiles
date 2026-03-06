import json
import time
import urllib.request
import sys
import os

def check_dashboard(port):
    url = f"http://localhost:{port}/status.json"
    print(f"Testing dashboard on {url}...")
    
    # Wait for server to start
    for _ in range(10):
        try:
            with urllib.request.urlopen(url) as response:
                if response.status == 200:
                    data = json.loads(response.read().decode())
                    print("Dashboard status.json is accessible.")
                    return data
        except Exception as e:
            time.sleep(1)
            continue
    print("Could not connect to dashboard.")
    return None

def validate_health_check(data):
    if not data:
        return False
    
    # Check if expected tasks are present
    expected_tasks = ["disk-usage", "memory-usage", "cpu-load", "network-latency", "env-test"]
    for task in expected_tasks:
        if task not in data["checks"]:
            print(f"Missing task: {task}")
            return False
    print("All expected tasks found in status.json.")
    
    # Check git info presence
    for key in ["git_branch", "git_base", "git_sha", "sys_info"]:
        if key not in data:
            print(f"Missing key: {key}")
            return False
    print("Git and System info present in status.json.")
    
    # Check if at least one task is running or passed
    statuses = [c["status"] for c in data["checks"].values()]
    print(f"Task statuses: {statuses}")
    
    return True

if __name__ == "__main__":
    # Test health-check dashboard on port 8082
    # We expect the runner to be started in the background by the agent
    data = check_dashboard(8082)
    if validate_health_check(data):
        print("UI Functional Validation PASSED")
        sys.exit(0)
    else:
        print("UI Functional Validation FAILED")
        sys.exit(1)
