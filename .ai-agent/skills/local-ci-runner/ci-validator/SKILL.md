---
name: ci-validator
description: Locally validates GitHub Actions workflows, secrets usage, and shell script integrity.
---

# CI Workflow Validator

Use this skill to run local checks on CI workflows and related scripts.

## Usage

Run with live browser dashboard (preferred for interactive use):
```bash
just -f ci-validator/Justfile dashboard
```

Run in parallel in terminal:
```bash
just -f ci-validator/Justfile parallel
```

## After Running

1. Report the dashboard URL to the user.
2. Wait for the user to confirm completion.
3. Once done, read `ci-validator/build/logs/<timestamp>/status.json` and report any failures.
4. If a task fails, use the dashboard or direct log access to investigate.
