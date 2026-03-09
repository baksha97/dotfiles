# AGENT.md

Project instructions for AI coding agents. `CLAUDE.md` is a symlink to this file for Claude Code compatibility.

## Commands

```bash
./main.sh setup [profile]        # Bootstrap the system — auto-detects OS (default: personal)
./main.sh brew backup [profile]  # Dump Homebrew state to meta/homebrew/Brewfile.<profile>
./main.sh alacritty-icon         # Replace Alacritty app icon
./main.sh install <pkg> [sub]    # Non-symlink "merge" installer (skills, zsh, fonts, git, all)
```

`main.sh` is the single entrypoint — it sources scripts from `meta/scripts/` rather than running them as subprocesses. OS detection happens in `main.sh`; platform-specific logic lives in `setup-macos.sh`, `setup-linux.sh`, and `setup-alpine.sh`, with shared logic in `setup-common.sh`.

## Architecture

**GNU Stow** is the core mechanism. Each directory under `stow/` mirrors `$HOME` and gets symlinked there via `stow -d stow <pkg> -t "$HOME" --adopt`. The `--adopt` flag moves pre-existing files into the repo and creates symlinks in place.

**Profiles** (`personal` / `work`) control two things:
1. Git identity — `stow/git/profiles/<name>` is copied to `stow/git/.gitconfig-profile` (gitignored), which `.gitconfig` includes via `[include]`
2. **macOS only**: Homebrew packages — `meta/homebrew/Brewfile.<profile>` is the source of truth
3. **Linux/Alpine**: Uses package list files in `meta/packages/` plus `install.d/` scripts regardless of profile

**VSCode/Cursor** stow target is platform-specific (`~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux), not `$HOME`.

**Agent skills** in `meta/skills/` are symlinked to `~/.copilot/skills`, `~/.cursor/skills`, `~/.agents/skills`, and `~/.claude/skills` during setup.

## Setup Scripts

| Script | Purpose |
|--------|---------|
| `setup-macos.sh` | macOS bootstrap (Homebrew install + bundle from Brewfile.<profile>) |
| `setup-linux.sh` | Linux bootstrap: sources lib/, loops install.d/shared/ + install.d/linux/, delegates to setup-common.sh |
| `setup-alpine.sh` | Alpine bootstrap: sources lib/, loops install.d/shared/, delegates to setup-common.sh |
| `setup-common.sh` | Shared bootstrap: SDKMAN!, loops stow.d/, git profile, agent skills |
| `backup.sh` | `brew bundle dump` into the active profile's Brewfile |
| `alacritty-icon.sh` | Replace Alacritty app icon |

## Composition Architecture

The setup scripts use the same file-loop pattern as `.zshrc.d/`: each concern lives in its own file, the orchestrating script just loops over them. **Adding a new item requires only adding one file — no edits to existing scripts.**

```
meta/scripts/
  lib/                     # Shared utilities sourced at the start of each platform script
    arch.sh                # ARCH_GO / ARCH_MUSL detection (exported)
    sudo.sh                # SUDO prefix detection (exported)
    github.sh              # gh_latest_version() helper function
  install.d/               # Per-tool installers (sourced in alphabetical order)
    shared/                # Tools installed on all Linux-family platforms
    linux/                 # Debian/Ubuntu-only tools
    linux-gui/             # GUI apps (sourced only when DISPLAY/WAYLAND is set)
  stow.d/                  # One file per stow package (sourced by setup-common.sh)
```

### Adding a new CLI tool

Create `meta/scripts/install.d/shared/<NN>-toolname.sh` (both platforms) or `meta/scripts/install.d/linux/<NN>-toolname.sh` (Linux only):

```bash
#!/bin/bash
# toolname — short description
command -v toolname &>/dev/null && return 0
echo "Installing toolname..."
curl -fsSL https://toolname.dev/install.sh | bash
```

### Adding a new stow package

1. Create `stow/<tool>/` mirroring `$HOME` structure
2. Create `meta/scripts/stow.d/<NN>-tool.sh`:

```bash
#!/bin/bash
# tool — short description
stow_backup "$HOME/.toolrc"
stow_package tool
```

`stow_backup` backs up and removes real files; symlinks are removed without backup. `stow_package` runs stow against `$STOW_TARGET` (default `$HOME`).

## Linux/Alpine Install Details

**Linux** (`setup-linux.sh`) installs in this order:
1. Source `lib/` utilities (arch, sudo, github helpers)
2. **apt packages** from `meta/packages/linux.packages`
3. Change shell to zsh
4. Source `install.d/shared/*.sh` then `install.d/linux/*.sh` (each tool guards with `command -v && return 0`)
5. Source `install.d/linux-gui/*.sh` (only when `DISPLAY`/`WAYLAND_DISPLAY`/`XDG_CURRENT_DESKTOP` is set)
6. Source `setup-common.sh` (SDKMAN!, stow, git profile, agent skills)
7. Install Gradle and Kotlin via SDKMAN!

**Alpine** (`setup-alpine.sh`) installs in this order:
1. Source `lib/` utilities
2. Enable community repo, install **apk packages** from `meta/packages/alpine.packages`
3. Change shell to zsh
4. Source `install.d/shared/*.sh`
5. Source `setup-common.sh`

## Key Files

| File | Purpose |
|------|---------|
| `meta/scripts/setup-macos.sh` | macOS bootstrap (Homebrew install + bundle) |
| `meta/scripts/setup-linux.sh` | Linux bootstrap orchestrator (~55 lines) |
| `meta/scripts/setup-alpine.sh` | Alpine bootstrap orchestrator (~50 lines) |
| `meta/scripts/setup-common.sh` | Shared bootstrap (SDKMAN!, stow.d loop, git profile, agent skills) |
| `meta/scripts/lib/arch.sh` | Architecture detection: sets ARCH, ARCH_GO, ARCH_MUSL |
| `meta/scripts/lib/sudo.sh` | Sudo prefix detection: sets SUDO |
| `meta/scripts/lib/github.sh` | `gh_latest_version OWNER REPO` helper |
| `meta/scripts/install.d/shared/` | Tool installers for Linux + Alpine |
| `meta/scripts/install.d/linux/` | Debian/Ubuntu-specific tool installers |
| `meta/scripts/install.d/linux-gui/` | GUI app installers (headful only) |
| `meta/scripts/stow.d/` | Per-package stow manifests |
| `meta/packages/linux.packages` | apt package list |
| `meta/packages/alpine.packages` | apk package list |
| `stow/zsh/.zshrc` | Zsh config — sources all `~/.zshrc.d/*.zsh` |
| `stow/zsh/.zshrc.d/` | Modular zsh configs (reference pattern for install.d/stow.d) |
| `stow/git/.gitconfig` | Global git config including `[include]` for the profile file |
| `stow/alacritty/.config/alacritty/alacritty.toml` | Terminal config; themes live in `themes/` subdirectory |
| `stow/alacritty/.config/linearmouse/linearmouse.json` | macOS mouse customization |

## Stow Packages

| Package | Target | Notes |
|---------|--------|-------|
| `zsh` | `$HOME` | `.zshrc`, `.zshrc.d/` |
| `powerlevel10k` | `$HOME` | `.p10k.zsh` |
| `tmux` | `$HOME` | `.tmux.conf` |
| `alacritty` | `$HOME` | `.config/alacritty/`, `.config/linearmouse/`, `.config/git/` |
| `git` | `$HOME` | `.gitconfig`, `.gitignore` |
| `claude` | `~/.claude/` | `settings.json`, `status-line.sh`, `commands/`, `agents/`, `scripts/` |
| `vscode` | Platform-specific VS Code `User/` | `settings.json`, `keybindings.json` |

## Conventions

- `backup/` holds timestamped snapshots of pre-existing config files that `setup.sh` would overwrite — never edit these
- `stow/git/.gitconfig-profile` is gitignored (per-machine identity)
- Device-specific configs inside `stow/alacritty/.config/` (anything other than `alacritty/`) are gitignored
- Profiles available: `personal`, `work`
- All `install.d/` and `stow.d/` scripts use `return` (not `exit`) since they are sourced, not executed
- `install.d/` scripts are idempotent: each guards with `command -v tool &>/dev/null && return 0`
