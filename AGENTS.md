# AGENTS.md

Project instructions for AI coding agents. `CLAUDE.md` is a symlink to this file for Claude Code compatibility.

## Commands

```bash
./main.sh setup [profile]        # Bootstrap the system — auto-detects OS, auto-detects profile on re-run
./main.sh brew backup [profile]  # Dump Homebrew state to meta/homebrew/Brewfile.<profile>
./main.sh alacritty-icon         # Replace Alacritty app icon
```

`main.sh` is the single entrypoint — it sources scripts from `meta/scripts/` rather than running them as subprocesses. OS detection happens in `main.sh`; platform-specific logic lives in `setup-macos.sh` and `setup-linux.sh`, with shared logic in `setup-common.sh`.

## Architecture

**Two platforms**: macOS and Linux (Debian/Ubuntu). Both share an identical script structure and converge on `setup-common.sh` for stow, git, and skills.

**GNU Stow** is the core mechanism. Each directory under `stow/` mirrors `$HOME` and gets symlinked there via `stow -d stow <pkg> -t "$HOME" --adopt`. The `--adopt` flag moves pre-existing files into the repo and creates symlinks in place.

**Profiles** (`personal` / `work`) control:
1. Git identity — `stow/git/profiles/<name>` is copied to `stow/git/.gitconfig-profile` (gitignored), which `.gitconfig` includes via `[include]`
2. **macOS only**: Homebrew packages — `meta/homebrew/Brewfile.<profile>` is the source of truth

Linux uses package list files in `meta/packages/` plus `install.d/` scripts regardless of profile.

On re-runs, the profile is auto-detected by comparing `.gitconfig-profile` against `stow/git/profiles/*`. Pass a profile name explicitly only to switch profiles.

**VSCode/Cursor** stow target is platform-specific (`~/Library/Application Support/Code/User` on macOS, `~/.config/Code/User` on Linux), not `$HOME`. Only stows if `code` is installed.

**Agent skills** in `meta/skills/` are symlinked to `~/.copilot/skills`, `~/.cursor/skills`, `~/.agents/skills`, and `~/.claude/skills` during setup.

## Cross-Platform Setup Flow

Both platform scripts follow the same structure:

```
DOTFILES_DIR → LIB → INSTALL_D → source profile.sh → resolve + validate profile
→ source sudo.sh → source arch.sh → source github.sh
→ platform packages (brew bundle / apt-get)
→ install.d/shared/ loop (+ linux/ merged on Linux)
→ setup-common.sh (SDKMAN!, stow.d loop, git profile, agent skills)
```

**macOS**: `brew bundle` installs most tools first, so shared scripts hit `command -v` guards and skip.
**Linux**: `shared/` and `linux/` scripts are merged and sorted by filename — numbering controls global install order (e.g. `linux/70-node` runs before `shared/80-vercel`).

## Setup Scripts

| Script | Purpose |
|--------|---------|
| `setup-macos.sh` | macOS bootstrap (Homebrew install + bundle, loops install.d/shared/) |
| `setup-linux.sh` | Linux bootstrap (apt install, merges install.d/shared/ + linux/ sorted by filename) |
| `setup-common.sh` | Shared bootstrap: SDKMAN!, loops stow.d/, git profile, agent skills |
| `backup.sh` | `brew bundle dump` into the active profile's Brewfile |
| `alacritty-icon.sh` | Replace Alacritty app icon |

## Composition Architecture

The setup scripts use the same file-loop pattern as `.zshrc.d/`: each concern lives in its own file, the orchestrating script just loops over them. **Adding a new item requires only adding one file — no edits to existing scripts.**

```
meta/scripts/
  lib/                     # Shared utilities sourced at the start of each platform script
    arch.sh                # ARCH / ARCH_GO / ARCH_MUSL detection (exported)
    sudo.sh                # SUDO prefix detection (exported)
    github.sh              # gh_latest_version() helper function
    profile.sh             # resolve_profile() — auto-detect or accept explicit profile
  install.d/               # Per-tool installers (sourced in numbered order)
    shared/                # Cross-platform (must work on macOS + Linux without platform guards)
    linux/                 # Linux-only (apt-specific, Linux paths, etc.)
    linux-gui/             # GUI apps (sourced only when DISPLAY/WAYLAND is set)
  stow.d/                  # One file per stow package (sourced by setup-common.sh)
```

### Script numbering

Scripts across `shared/` and `linux/` share a single number line. On Linux, both directories are merged and sorted by filename:

| Range | Purpose | Examples |
|-------|---------|----------|
| 10–40 | Standalone tools (no deps) | lazygit, zoxide, yq, uv |
| 50–60 | Linux-specific standalone tools | nerd-fonts, docker-compose, tailscale |
| 70–72 | Node.js ecosystem setup | node (linux), nvm (linux) |
| 74–76 | Package managers depending on node | pnpm, agent-browser |
| 80–90 | npm-installed CLIs (require npm prerequisite guard) | vercel, gemini-cli |
| 95–99 | Late installers | opencode, claude |

### Adding a new CLI tool

Create `meta/scripts/install.d/shared/<NN>-toolname.sh` (cross-platform) or `meta/scripts/install.d/linux/<NN>-toolname.sh` (Linux only):

```bash
#!/bin/bash
# toolname — short description
command -v toolname &>/dev/null && return 0
echo "Installing toolname..."
curl -fsSL https://toolname.dev/install.sh | bash
```

**`shared/` rules**: no Darwin guards, no `apt-get` guards, no platform-specific conditionals in guards. If a script needs those, it belongs in `linux/`. Inline OS detection for binary download URLs (e.g. `[[ "$(uname)" == "Darwin" ]] && OS="darwin"`) is fine — that's not a guard.

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

## Idempotency

Every component is designed for safe re-runs:

- **`install.d/` scripts** guard with `command -v tool && return 0`. For tools that install to `~/.local/bin` (not on PATH in non-interactive bash), add a fallback: `[ -f "$HOME/.local/bin/tool" ] && return 0`
- **npm-installed tools** add `command -v npm || { echo "Skipped ..."; return 0; }` as a prerequisite guard
- **Nerd fonts** use per-font marker files (`.installed-FontName-vX.Y.Z`) for version-aware idempotency
- **nvm** checks `[ -s "$HOME/.nvm/nvm.sh" ]` since it's a shell function, not a binary
- **`stow --adopt`** is idempotent — re-stowing adopted files is a no-op
- **Git profile** copy is guarded by `cmp -s` — skips if unchanged
- **Skills symlinks** are recreated each run (rm + ln -s) — idempotent
- **Version detection** uses `gh_latest_version` — always fetches the latest release, never hardcodes versions

## Key Files

| File | Purpose |
|------|---------|
| `meta/scripts/setup-macos.sh` | macOS bootstrap (Homebrew install + bundle + shared loop) |
| `meta/scripts/setup-linux.sh` | Linux bootstrap orchestrator (apt + merged install loop) |
| `meta/scripts/setup-common.sh` | Shared bootstrap (SDKMAN!, stow.d loop, git profile, agent skills) |
| `meta/scripts/lib/arch.sh` | Architecture detection: sets ARCH, ARCH_GO, ARCH_MUSL |
| `meta/scripts/lib/sudo.sh` | Sudo prefix detection: sets SUDO |
| `meta/scripts/lib/github.sh` | `gh_latest_version OWNER REPO` helper |
| `meta/scripts/lib/profile.sh` | `resolve_profile [name]` — auto-detect or accept explicit profile |
| `meta/scripts/install.d/shared/` | Cross-platform tool installers (must work on macOS + Linux) |
| `meta/scripts/install.d/linux/` | Linux-only tool installers |
| `meta/scripts/install.d/linux-gui/` | GUI app installers (headful only) |
| `meta/scripts/stow.d/` | Per-package stow manifests |
| `meta/packages/linux.packages` | apt package list |
| `stow/zsh/.zshrc` | Zsh config — sources all `~/.zshrc.d/*.zsh` (just the loop, nothing else) |
| `stow/zsh/.zshrc.d/` | Modular zsh configs, numbered-prefix ordering: `00-` first, `50-` default, `99-` last |
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
| `vscode` | Platform-specific VS Code `User/` | `settings.json`, `keybindings.json` (only if `code` is installed) |

## Conventions

- `backup/` holds timestamped snapshots of pre-existing config files that `setup.sh` would overwrite — never edit these
- `stow/git/.gitconfig-profile` is gitignored (per-machine identity)
- Device-specific configs inside `stow/alacritty/.config/` (anything other than `alacritty/`) are gitignored
- Profiles available: `personal`, `work`
- All `install.d/` and `stow.d/` scripts use `return` (not `exit`) since they are sourced, not executed
- `install.d/` scripts are idempotent: guard with `command -v` + fallback path check for `~/.local/bin` installers
- `shared/` scripts must not contain platform guards — only `command -v` and prerequisite guards
- Core CLI tools belong in both Brewfile.personal and Brewfile.work unless genuinely profile-specific
- Never hardcode tool versions — use `gh_latest_version` for GitHub releases
