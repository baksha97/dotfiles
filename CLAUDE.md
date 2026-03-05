# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
./main.sh setup [profile]        # Bootstrap the system — auto-detects OS (default: personal)
./main.sh brew backup [profile]  # Dump Homebrew state to meta/homebrew/Brewfile.<profile>
./main.sh alacritty-icon         # Replace Alacritty app icon
```

`main.sh` is the single entrypoint — it sources scripts from `meta/scripts/` rather than running them as subprocesses (`source`, not `exec`). OS detection happens in `main.sh`; platform-specific logic lives in `setup-macos.sh` and `setup-linux.sh`, with shared logic in `setup-common.sh`.

## Architecture

**GNU Stow** is the core mechanism. Each directory under `stow/` mirrors `$HOME` and gets symlinked there via `stow -d stow <pkg> -t "$HOME" --adopt`. The `--adopt` flag moves pre-existing files into the repo and creates symlinks in place.

**Profiles** (`personal` / `work`) control two things:
1. Git identity — `stow/git/profiles/<name>` is copied to `stow/git/.gitconfig-profile` (gitignored), which `.gitconfig` includes via `[include]`
2. Homebrew packages (macOS only) — `meta/homebrew/Brewfile.<profile>` is the source of truth; Linux uses `meta/packages/linux.packages` (apt) plus tool-specific install scripts regardless of profile

**VSCode/Cursor** stow target is platform-specific (`~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux), not `$HOME`.

**Agent skills** in `meta/.ai-agent/skills/` are symlinked to `~/.copilot/skills` and `~/.cursor/skills` during setup.

## Key Files

| File | Purpose |
|------|---------|
| `meta/scripts/setup-macos.sh` | macOS bootstrap (Homebrew install + bundle) |
| `meta/scripts/setup-linux.sh` | Linux bootstrap (apt + official installers for gh, lazygit, zoxide, yq, just, uv, typos, Docker, Tailscale, Nerd Fonts) |
| `meta/scripts/setup-common.sh` | Shared bootstrap logic (SDKMAN!, stow, git profile, agent skills) |
| `meta/scripts/backup.sh` | `brew bundle dump` into the active profile's Brewfile |
| `meta/packages/linux.packages` | apt package list for Linux setup |
| `stow/zsh/.zshrc` | Zsh config with Zinit plugins, `gct`/`grmt` worktree functions, fzf/zoxide integrations |
| `stow/git/.gitconfig` | Global git config including `[include]` for the profile file |
| `stow/alacritty/.config/alacritty/alacritty.toml` | Terminal config; themes live in `themes/` subdirectory |

## Adding a New Stow Package

1. Create `stow/<tool>/` mirroring `$HOME` structure
2. Add `stow -d stow <tool> -t "$HOME" --adopt` to `meta/scripts/setup.sh`

## Conventions

- `backup/` holds timestamped snapshots of pre-existing config files that `setup.sh` would overwrite — never edit these
- `stow/git/.gitconfig-profile` is gitignored (per-machine identity)
- Device-specific configs inside `stow/alacritty/.config/` (anything other than `alacritty/`) are gitignored
