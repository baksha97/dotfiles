---
name: local-ci-runner
description: A universal Python-based runner for asynchronous tasks and GitHub Workflows with real-time visualization. Adaptively generates or uses task presets to run local CI checks.
---

# Adaptive Async Runner

Use this skill to execute and monitor collections of tasks or GitHub Workflow jobs with a real-time browser dashboard. This skill is **adaptive** and will either use a pre-defined preset or generate a custom task suite based on the project's CI files.

## Workflow: Research -> Match -> Adapt

### 1. Research
When a user asks to "run CI" or "check project," the agent should:
- Look for `.github/workflows/*.yml` files.
- Identify the project type (Android, Node, Swift, etc.) via `package.json`, `build.gradle`, etc.

### 2. Match
- If a matching preset exists in `<SKILL-DIR>/presets/` (e.g., `android-integrity.yaml`), use it as the base.

### 3. Adapt
- If no preset matches, or the user has a specific/narrow request (e.g., "only run the UI tests"), **dynamically generate** a `tasks.yaml` in the project root or `/tmp`.
- **Prefer Workflow Binding**: When generating, reference `workflow_step` names from the `.github/workflows/` files to ensure local runs stay in sync with CI.

## Usage

Run the runner with either a preset or a generated YAML:
```bash
uv run async-runner --tasks-yaml <path-to-yaml> --dashboard
```

## Dashboard Features

- **Live UI**: Real-time status badges, global timer, and git/system context.
- **Log Streaming**: Click any task row in the browser to stream logs live.
- **Stop Button**: Instantly kills the entire process group to avoid orphaned tasks.

## Why this is robust

- **Single Source of Truth**: By referencing `workflow_step`, we inherit the exact `run:` command, `env:`, and `working-directory` from your CI.
- **Zero Boilerplate**: The agent handles the discovery and YAML generation for you.
- **Context Aware**: If you ask "what's failing in the TV job?", the agent can generate a YAML that targets **only** that specific job's steps.
