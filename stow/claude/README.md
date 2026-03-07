# Claude Code Config

Claude Code configuration managed as a [GNU Stow](https://www.gnu.org/software/stow/) package in [dotfiles](https://github.com/trstringer/dotfiles). Running `./main.sh setup` symlinks everything here into `~/.claude/`.

## What's Managed

| Path | Purpose |
|------|---------|
| `settings.json` | Global Claude Code settings — env vars, permissions, status line, marketplaces |
| `status-line.sh` | Custom status bar showing model, git branch, token usage, cost, and session time |
| `commands/` | Custom slash commands (see below) |
| `agents/` | Specialized subagents (see below) |
| `scripts/` | Utility scripts for maintaining the Claude Code setup |

## Commands

Invoked with `/<command> [arguments]` in any Claude Code session.

### Analysis & Reflection

| Command | Description |
|---------|-------------|
| `/think-harder [problem]` | Enhanced multi-dimensional analytical thinking |
| `/think-ultra [problem]` | Ultra-comprehensive 7-phase analysis framework |
| `/reflection` | Analyze conversation history and improve `CLAUDE.md` instructions |
| `/reflection-harder` | Comprehensive session analysis and learning capture |
| `/eureka [breakthrough]` | Document technical breakthroughs into reusable `breakthroughs/` files |

### GitHub Integration

| Command | Description |
|---------|-------------|
| `/gh:review-pr [PR]` | Thorough code review with inline GitHub API comments |
| `/gh:fix-issue [issue]` | Full issue resolution: plan → branch → implement → test → PR |

### Utilities

| Command | Description |
|---------|-------------|
| `/cc:create-command [name]` | Scaffold a new Claude Code custom command with best-practice structure |
| `/translate [text]` | Translate English/Japanese tech content to natural Chinese |

## Agents

Subagents are invoked automatically by Claude Code based on task context.

| Agent | Trigger / Use |
|-------|--------------|
| `pr-reviewer` | Code review with correctness, security, and convention focus |
| `github-issue-fixer` | Plan → implement → test → PR workflow for GitHub issues |
| `instruction-reflector` | Prompt-engineer improvements to `CLAUDE.md` |
| `deep-reflector` | Session retrospective — extract patterns and preferences |
| `insight-documenter` | Capture technical breakthroughs as structured docs |
| `command-creator` | Scaffold well-structured Claude Code custom commands |
| `gemini-analyzer` | Delegate large codebase analysis to Gemini CLI |
| `ui-engineer` | Frontend/React development and component architecture |

## Scripts

| Script | Usage |
|--------|-------|
| `update-cc-plugins.sh` | `bash ~/.claude/scripts/update-cc-plugins.sh` — refreshes all marketplaces and updates every installed plugin in one shot |

## What's Not Managed Here

The following live in `~/.claude/` but are intentionally excluded from dotfiles — they're either sensitive or machine-specific:

- `config.json` — API key (`primaryApiKey`)
- `settings/` — per-provider credential files (azure, deepseek, openrouter, vertex, etc.)
- `.mcp.json` — MCP server config (machine-specific)
- `projects/`, `tasks/`, `history.jsonl`, `cache/`, `todos/` — runtime/session state
