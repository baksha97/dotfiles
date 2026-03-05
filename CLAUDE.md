# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
./main.sh setup [profile]        # Bootstrap the system — auto-detects OS (default: personal)
./main.sh brew backup [profile]  # Dump Homebrew state to meta/homebrew/Brewfile.<profile>
./main.sh alacritty-icon         # Replace Alacritty app icon
```

### Setup Options
- `--dry-run`: Show what would be done without making changes
- `--with-gui`: Install GUI applications (VS Code, Chrome, etc.)
- `--with-fonts`: Install all Nerd Fonts (can be slow)
- `--verbose`: Enable verbose output (set -x)

`main.sh` is the single entrypoint — it sources scripts from `meta/scripts/` rather than running them as subprocesses (`source`, not `exec`). OS detection happens in `main.sh`; platform-specific logic lives in `setup-macos.sh` and `setup-linux.sh`, with shared logic in `setup-common.sh`.

## Architecture

**GNU Stow** is the core mechanism. Each directory under `stow/` mirrors `$HOME` and gets symlinked there via `stow -d stow <pkg> -t "$HOME" --adopt`. The `--adopt` flag moves pre-existing files into the repo and creates symlinks in place.

**Profiles** (`personal` / `work`) control two things:
1. Git identity — `stow/git/profiles/<name>` is copied to `stow/git/.gitconfig-profile` (gitignored), which `.gitconfig` includes via `[include]`
2. **macOS only**: Homebrew packages — `meta/homebrew/Brewfile.<profile>` is the source of truth
3. **Linux**: Uses `meta/packages/linux.packages` (apt) plus tool-specific install scripts regardless of profile

**VSCode/Cursor** stow target is platform-specific (`~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux), not `$HOME`. **Settings are merged** automatically to preserve machine-specific keys (themes, AI configs) using `meta/scripts/merge-helpers.sh`.

**Agent skills** in `meta/.ai-agent/skills/` are symlinked to `~/.copilot/skills` and `~/.cursor/skills` during setup.

## Setup Scripts

| Script | Purpose |
|--------|---------|
| `setup-macos.sh` | macOS bootstrap (Homebrew install + bundle from Brewfile.<profile>) |
| `setup-linux.sh` | Linux bootstrap (apt + official installers). GUI apps and Nerd Fonts are opt-in via flags. |
| `setup-common.sh` | Shared bootstrap logic (SDKMAN!, stow packages, git profile, agent skills, shell change) |
| `backup.sh` | `brew bundle dump` into the active profile's Brewfile |
| `alacritty-icon.sh` | Replace Alacritty app icon |
| `merge-helpers.sh` | JSON merging logic for VSCode settings |

## Linux Setup Details

The Linux setup (`setup-linux.sh`) installs packages in this order:

1. **apt packages** from `meta/packages/linux.packages`
2. **CLI tools** via official install scripts: gh CLI, lazygit, zoxide, yq, just, uv, Docker, Docker Compose plugin, Tailscale, Node.js LTS, vercel, typos, opencode
3. **Nerd Fonts** (Opt-in with `--with-fonts`)
4. **GUI apps** (Opt-in with `--with-gui`)
5. **SDKMAN!** then installs Gradle and Kotlin (skipped if `mise` manages them)

## Key Files

| File | Purpose |
|------|---------|
| `meta/scripts/setup-macos.sh` | macOS bootstrap (Homebrew install + bundle) |
| `meta/scripts/setup-linux.sh` | Linux bootstrap (apt + official installers) |
| `meta/scripts/setup-common.sh` | Shared bootstrap logic (SDKMAN!, stow, git profile, agent skills) |
| `meta/scripts/merge-helpers.sh` | JSON merging logic |
| `meta/config/merge-keys-vscode.txt` | VSCode keys to preserve during setup |
| `stow/zsh/.zshrc` | Zsh config with Zinit plugins |
| `stow/git/.gitconfig` | Portable git config using `gh auth git-credential` |
| `stow/alacritty/.config/alacritty/alacritty.toml` | Modular Alacritty config (imports `font.toml`, `theme.toml`) |

## Stow Packages

| Package | Target | Notes |
|---------|--------|-------|
| `zsh` | `$HOME` | `.zshrc`, `.zshrc.d/` |
| `powerlevel10k` | `$HOME` | `.p10k.zsh` |
| `tmux` | `$HOME` | `.tmux.conf` |
| `alacritty` | `$HOME` | Modular config under `.config/alacritty/` |
| `git` | `$HOME` | `.gitconfig`, `.gitignore` |
| `vscode` | Platform-specific VS Code `User/` | `settings.json`, `keybindings.json` (merged) |

## Conventions

- `backup/` holds timestamped snapshots of pre-existing config files — never edit these
- `stow/git/.gitconfig-profile` is gitignored (per-machine identity)
- JSON files (like VSCode settings) are merged instead of overwritten when possible
- Setup is idempotent; run multiple times safely
- Use `--dry-run` to preview changes before applying
