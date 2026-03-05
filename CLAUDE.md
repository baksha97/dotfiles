# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
./main.sh setup [profile]        # Bootstrap the system — auto-detects OS (default: personal)
./main.sh brew backup [profile]  # Dump Homebrew state to meta/homebrew/Brewfile.<profile>
./main.sh alacritty-icon         # Replace Alacritty app icon
./main.sh install <pkg> [sub]    # Non-symlink "merge" installer (skills, zsh, fonts, git, all)
```

`main.sh` is the single entrypoint — it sources scripts from `meta/scripts/` rather than running them as subprocesses. OS detection happens in `main.sh`; platform-specific logic lives in `setup-macos.sh` and `setup-linux.sh`, with shared logic in `setup-common.sh`.

## Architecture

**GNU Stow** is the core mechanism. Each directory under `stow/` mirrors `$HOME` and gets symlinked there via `stow -d stow <pkg> -t "$HOME" --adopt`. The `--adopt` flag moves pre-existing files into the repo and creates symlinks in place.

**Profiles** (`personal` / `work`) control two things:
1. Git identity — `stow/git/profiles/<name>` is copied to `stow/git/.gitconfig-profile` (gitignored), which `.gitconfig` includes via `[include]`
2. **macOS only**: Homebrew packages — `meta/homebrew/Brewfile.<profile>` is the source of truth
3. **Linux**: Uses `meta/packages/linux.packages` (apt) plus tool-specific install scripts regardless of profile

**VSCode/Cursor** stow target is platform-specific (`~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux), not `$HOME`.

**Agent skills** in `meta/.ai-agent/skills/` are symlinked to `~/.copilot/skills` and `~/.cursor/skills` during setup.

## Setup Scripts

| Script | Purpose |
|--------|---------|
| `setup-macos.sh` | macOS bootstrap (Homebrew install + bundle from Brewfile.<profile>) |
| `setup-linux.sh` | Linux bootstrap (apt + official installers for gh, lazygit, zoxide, yq, just, uv, typos, Docker, Tailscale, Nerd Fonts, plus GUI apps in headful environments) |
| `setup-common.sh` | Shared bootstrap logic (SDKMAN!, stow packages, git profile, agent skills) |
| `backup.sh` | `brew bundle dump` into the active profile's Brewfile |
| `alacritty-icon.sh` | Replace Alacritty app icon |

## Linux Setup Details

The Linux setup (`setup-linux.sh`) installs packages in this order:

1. **apt packages** from `meta/packages/linux.packages` (ca-certificates, curl, git, git-lfs, stow, zsh, tmux, fzf, jq, rclone, fontconfig, unzip, zip, aria2, ffmpeg, ansible, exiftool, scrcpy)
2. **CLI tools** via official install scripts: gh CLI, lazygit, zoxide, yq, just, uv, Docker, Docker Compose plugin, Tailscale, Node.js LTS, vercel, typos, opencode
3. **Nerd Fonts** to `~/.local/share/fonts/`
4. **GUI apps** (only in headful environments): VS Code, VS Code Insiders, Google Chrome (amd64), Firefox, VLC, Alacritty, Android Studio
5. **SDKMAN!** then installs Gradle and Kotlin

## Key Files

| File | Purpose |
|------|---------|
| `meta/scripts/setup-macos.sh` | macOS bootstrap (Homebrew install + bundle) |
| `meta/scripts/setup-linux.sh` | Linux bootstrap (apt + official installers) |
| `meta/scripts/setup-common.sh` | Shared bootstrap logic (SDKMAN!, stow, git profile, agent skills) |
| `meta/scripts/backup.sh` | `brew bundle dump` into the active profile's Brewfile |
| `meta/packages/linux.packages` | apt package list for Linux setup |
| `stow/zsh/.zshrc` | Zsh config with Zinit plugins, `gct`/`grmt` worktree functions, fzf/zoxide integrations |
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
| `vscode` | Platform-specific VS Code `User/` | `settings.json`, `keybindings.json` |

## Conventions

- `backup/` holds timestamped snapshots of pre-existing config files that `setup.sh` would overwrite — never edit these
- `stow/git/.gitconfig-profile` is gitignored (per-machine identity)
- Device-specific configs inside `stow/alacritty/.config/` (anything other than `alacritty/`) are gitignored
- Profiles available: `personal`, `work`

## Adding a New Stow Package

1. Create `stow/<tool>/` mirroring `$HOME` structure
2. Add `stow -d stow <tool> -t "$HOME" --adopt` to `meta/scripts/setup-common.sh`
