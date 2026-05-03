# Dotfiles

Personal development environment managed with [GNU Stow](https://www.gnu.org/software/stow/) and driven through a single `main.sh` entrypoint. One command bootstraps a fresh macOS or Linux (Debian/Ubuntu) machine with shell, editor, terminal, git, and AI agent skill configurations.

## Table of Contents

- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Cross-Platform Architecture](#cross-platform-architecture)
- [Repository Structure](#repository-structure)
- [Stow Packages](#stow-packages)
- [What Gets Installed](#what-gets-installed)
- [Profiles](#profiles)
- [Agent Skills](#agent-skills)
- [Shell Configuration](#shell-configuration)
- [Tmux Configuration](#tmux-configuration)
- [Alacritty Configuration](#alacritty-configuration)
- [VS Code / Cursor Configuration](#vs-code--cursor-configuration)
- [Utility Commands](#utility-commands)
- [Custom Shell Functions](#custom-shell-functions)
- [Adding New Configurations](#adding-new-configurations)

## Quick Start

```bash
git clone git@github.com:baksha97/dotfiles.git ~/dotfiles
cd ~/dotfiles
./main.sh setup --adopt  # first setup: backs up known conflicts and adopts remaining conflicts
./main.sh setup          # normal rerun: restows existing links
./main.sh setup work     # setup with the "work" profile
```

### All Commands

```bash
./main.sh setup [profile] [flags]  # bootstrap the system (auto-detects OS and profile on re-run)
./main.sh brew backup [profile]    # dump current Homebrew state to Brewfile.<profile>
./main.sh test                     # run setup smoke checks
./main.sh alacritty-icon           # replace the Alacritty app icon
```

Useful setup flags:
- `--adopt` — let Stow adopt remaining unhandled conflicts; use for first setup or explicit repair
- `--dry-run` / `-n` — show setup and stow actions without mutating files
- `--skip-platform-packages` — skip Homebrew/apt package installation
- `--skip-brew` / `--no-brew` — macOS alias for `--skip-platform-packages`
- `--skip-installers`, `--skip-sdkman`, `--skip-stow` — skip individual phases

## How It Works

This repository uses **GNU Stow** to manage dotfiles. Each directory inside `stow/` is a "stow package" whose internal structure mirrors where the files should live relative to `$HOME`. Stow creates symlinks from your home directory into this repo, so every config file is version-controlled in one place.

Normal setup uses `stow --restow`, which refreshes existing links without pulling app-generated local changes into the repo. Pass `--adopt` for first setup or explicit repair; known conflicting files are path-backed up and removed first, and Stow can then move remaining conflicts into the matching package. After an adopt run, review `git diff` before committing.

```
stow/
├── zsh/
│   └── .zshrc              →  ~/.zshrc
├── tmux/
│   └── .tmux.conf          →  ~/.tmux.conf
├── git/
│   ├── .gitconfig          →  ~/.gitconfig
│   └── .gitignore          →  ~/.gitignore
├── alacritty/
│   ├── .config/alacritty/  →  ~/.config/alacritty/
│   └── .config/linearmouse/ →  ~/.config/linearmouse/ (macOS mouse config)
└── ...
```

### Composition Pattern

The setup scripts mirror the `.zshrc.d/` pattern: **adding a new tool or stow package requires only dropping one file** — no edits to existing scripts.

- `meta/scripts/install.d/shared/` — cross-platform tool installers (must work on macOS + Linux)
- `meta/scripts/install.d/linux/` — Linux-only tools (apt-specific, Linux paths)
- `meta/scripts/install.d/linux-gui/` — GUI apps (headful only)
- `meta/scripts/stow.d/` — one stow manifest per package

## Cross-Platform Architecture

Both macOS and Linux follow the same setup structure:

```
parse args → resolve profile → platform packages → install.d loop → setup-common.sh
```

**macOS** (`setup-macos.sh`): Homebrew installs most tools via `brew bundle`, then `shared/` scripts run — most hit their `command -v` guard and skip since brew already installed the tool. Pass `--skip-brew` or `--skip-platform-packages` to bypass Homebrew install/update/bundle and rely on already-installed tools plus the non-brew shared installers.

**Linux** (`setup-linux.sh`): apt installs base packages, then `shared/` and `linux/` scripts are **merged and sorted by filename** so numbering controls global install order. This ensures dependencies are respected (e.g. `linux/70-node` runs before `shared/80-vercel`).

### Strict `shared/` vs `linux/` separation

- **`shared/`**: Scripts must work on both macOS and Linux **without platform guards**. No `[[ "$(uname)" == "Darwin" ]] && return 0`, no `command -v apt-get || return 0`. If a script would fail on macOS, it belongs in `linux/`.
- **`linux/`**: Linux-only install methods — apt repos, Linux font paths, shell functions without a binary to check.

Inline OS detection for binary download URLs is fine in `shared/` (e.g. `[[ "$(uname)" == "Darwin" ]] && OS="darwin"`) — that's selecting the right binary, not guarding execution.

### Script numbering

Scripts across both directories share a single number line:

| Range | Purpose | Examples |
|-------|---------|----------|
| 10–40 | Standalone tools (no deps) | lazygit, zoxide, yq, uv |
| 50–60 | Linux-specific standalone tools | nerd-fonts, docker-compose, tailscale |
| 70–72 | Node.js ecosystem setup | node (linux), nvm (linux) |
| 74–76 | Package managers depending on node | pnpm, agent-browser |
| 80–90 | npm-installed CLIs | vercel, gemini-cli |
| 95–99 | Late installers | opencode, claude |

### Idempotency

Every setup component is designed for safe re-runs:

| Component | Guard mechanism |
|-----------|----------------|
| `install.d/` scripts | `command -v tool && return 0` + fallback path check for `~/.local/bin` installers |
| npm-installed tools | `npm_install_global_if_needed package binary label` from `lib/npm.sh` |
| Nerd fonts (linux) | Per-font marker files (`.installed-FontName-vX.Y.Z`) |
| nvm (linux) | `[ -s "$HOME/.nvm/nvm.sh" ] && return 0` (shell function, not binary) |
| Stow packages | Default `stow --restow`; explicit `--adopt` for first setup/repair |
| Git profile | `cmp -s` guard — skips copy if unchanged |
| Skills symlinks | Recreated each run (rm + ln -s) |
| Version detection | `gh_latest_version` — always latest, never hardcoded |

## Repository Structure

```
dotfiles/
├── main.sh                        # Single entrypoint for all commands
├── stow/                          # GNU Stow packages (symlinked to $HOME)
│   ├── alacritty/                 # Alacritty terminal emulator config
│   │   └── .config/
│   │       ├── alacritty/
│   │       │   ├── alacritty.toml
│   │       │   └── themes/        # 130+ color themes
│   │       ├── linearmouse/       # macOS mouse configuration
│   │       └── git/               # Git ignore templates
│   ├── claude/                    # Claude Code settings, commands, agents, scripts
│   ├── git/                       # Git config and profiles
│   │   ├── .gitconfig
│   │   ├── .gitignore             # Global gitignore
│   │   └── profiles/
│   │       ├── personal           # Name + email for personal projects
│   │       └── work               # Name + email for work projects
│   ├── powerlevel10k/             # Powerlevel10k prompt theme
│   │   └── .p10k.zsh
│   ├── tmux/                      # tmux terminal multiplexer config
│   │   └── .tmux.conf
│   ├── vscode/                    # VS Code / Cursor editor settings
│   │   ├── settings.json
│   │   └── keybindings.json
│   └── zsh/                       # Zsh shell config
│       ├── .zshrc                 # Sources all .zshrc.d/*.zsh (just the loop)
│       └── .zshrc.d/              # Modular zsh configs (00-first, 50-default, 99-last)
└── meta/                          # Support files (not stowed)
    ├── skills/                    # AI coding agent skills (symlinked to tool paths)
    ├── homebrew/                   # Homebrew package management (macOS only)
    │   ├── Brewfile.personal
    │   └── Brewfile.work
    ├── packages/                   # Linux package lists
    │   └── linux.packages          # apt packages for Debian/Ubuntu setup
    └── scripts/                    # Implementation scripts
        ├── lib/                    # Shared utilities (sourced first by platform scripts)
        │   ├── arch.sh             # ARCH_GO / ARCH_MUSL detection
        │   ├── sudo.sh             # SUDO prefix detection
        │   ├── github.sh           # gh_latest_version() helper
        │   └── profile.sh          # resolve_profile() — auto-detect or accept explicit
        ├── install.d/              # Per-tool installers (one file = one tool)
        │   ├── shared/             # Cross-platform (must work on macOS + Linux)
        │   ├── linux/              # Linux-only tools
        │   └── linux-gui/          # GUI apps (headful environments only)
        ├── stow.d/                 # Per-package stow manifests (one file = one package)
        ├── setup-macos.sh          # macOS bootstrap (Homebrew + shared loop)
        ├── setup-linux.sh          # Linux bootstrap (apt + merged install loop)
        ├── setup-common.sh         # Shared stow/git/skills setup
        ├── backup.sh               # Brewfile dump
        └── alacritty-icon.sh       # Icon replacement
```

## Stow Packages

All stow packages live under `stow/`. The table below shows where each package's files end up:

| Package | Contents | Symlink Target |
|---------|----------|----------------|
| `zsh` | `.zshrc`, `.zshrc.d/` | `$HOME` |
| `powerlevel10k` | `.p10k.zsh` | `$HOME` |
| `tmux` | `.tmux.conf` | `$HOME` |
| `alacritty` | `.config/alacritty/`, `.config/linearmouse/`, `.config/git/` | `$HOME` |
| `git` | `.gitconfig`, `.gitignore` | `$HOME` |
| `bin` | `.local/bin/hcli` (homelab CLI wrapper) | `$HOME` |
| `claude` | `settings.json`, `status-line.sh`, `commands/`, `agents/`, `scripts/` | `~/.claude/` |
| `vscode` | `settings.json`, `keybindings.json` | Platform-specific VS Code `User/` directory |

VS Code target paths:
- **macOS**: `~/Library/Application Support/Code/User`
- **Linux**: `~/.config/Code/User`

## What Gets Installed

The `setup` command performs these steps in order:

1. **Resolve profile** — auto-detects from previous setup or uses explicit argument (defaults to `personal`)
2. **Source lib utilities** — args, profile, sudo, arch, github, npm helpers
3. **Show hidden files** in Finder (macOS) or Nautilus (Linux)
4. **Platform-specific package installation:**
   - **macOS**: Install Homebrew (if missing), then `brew bundle` from `meta/homebrew/Brewfile.<profile>` unless skipped
   - **Linux**: Install apt packages from `meta/packages/linux.packages`, change shell to zsh unless skipped
5. **Install.d loop** — each script installs one tool with idempotency guards
   - **macOS**: loops `shared/` only (brew already installed most tools)
   - **Linux**: merges `shared/` + `linux/` sorted by filename for dependency ordering
6. **Install SDKMAN!** for JVM SDK management
7. **Stow all packages** — each `stow.d/` script backs up conflicts and restows one package; `--adopt` enables adoption
8. **Set git profile** — copies the chosen identity into `~/.gitconfig-profile`
9. **Symlink Agent Skills** — makes skills discoverable by Copilot, Cursor, and other agents
10. **Linux SDKMAN packages** — installs Gradle and Kotlin (Linux only)

`--dry-run` skips package installers and SDKMAN, then runs stow planning with `--simulate`.

### Tool Installation Matrix

**Cross-platform tools** (`shared/` — run on macOS + Linux):

| Tool | macOS source | Linux source |
|------|-------------|--------------|
| lazygit | brew → skip | `shared/10` (GitHub binary) |
| zoxide | brew → skip | `shared/20` (install script) |
| yq | brew → skip | `shared/30` (GitHub binary) |
| uv | brew → skip | `shared/40` (install script) |
| pnpm | brew → skip | `shared/74` (install script) |
| agent-browser | brew → skip | `shared/76` (npm) |
| vercel | brew → skip | `shared/80` (npm) |
| gemini-cli | `shared/90` (npm) | `shared/90` (npm) |
| claude | `shared/99` (install script) | `shared/99` (install script) |

**Linux-only tools** (`linux/`):

| Tool | Source |
|------|--------|
| gh CLI | `linux/10` (apt repo) |
| fzf (latest) | `linux/20` (GitHub binary) |
| just | `linux/30` (install script) |
| docker | `linux/40` (get.docker.com) |
| docker-compose | `linux/50` (GitHub plugin) |
| nerd-fonts | `linux/50` (GitHub tarballs, latest version) |
| tailscale | `linux/60` (install script) |
| node | `linux/70` (NodeSource apt) |
| nvm | `linux/72` (install script) |
| opencode | `linux/95` (install script) |

### macOS Brewfile Highlights

| Category | Packages |
|----------|----------|
| **CLI tools** | `fzf`, `zoxide`, `tmux`, `stow`, `curl`, `ffmpeg`, `jq`, `yq`, `typos-cli` |
| **Dev runtimes** | `node`, `nvm`, `pnpm`, `uv` |
| **Containers** | `docker`, `colima`, `act` (local GitHub Actions) |
| **AI tools** | `agent-browser`, `vercel-cli` |
| **Fonts** | JetBrains Mono, Fira Code, Mononoki, Roboto Mono, and more (all Nerd Font variants) |
| **Apps** | Alacritty, VS Code, Google Chrome, Rectangle, Spotify, Multipass |

### Linux Installation Details

**apt packages** (`meta/packages/linux.packages`):
- Core: `git`, `git-lfs`, `curl`, `zsh`, `tmux`, `stow`, `fzf`, `jq`
- Media: `ffmpeg`, `scrcpy`
- Tools: `rclone`, `aria2`, `ansible`, `exiftool`
- Utilities: `fontconfig`, `unzip`, `zip`, `ca-certificates`

**GUI apps** (`install.d/linux-gui/` — headful environments only):
- VS Code, VS Code Insiders, Google Chrome (amd64 only), Firefox, VLC, Alacritty, Android Studio

## Profiles

Profiles control git identity and (on macOS) which Homebrew packages are installed. Linux uses the same package lists regardless of profile.

On re-runs, the active profile is auto-detected by comparing `.gitconfig-profile` against `stow/git/profiles/*`. Pass a profile name explicitly only to switch profiles. Fresh machines default to `personal`.

Available profiles:
- `personal` — Full macOS setup with GUI apps
- `work` — Work environment setup

```bash
./main.sh setup          # auto-detects profile (defaults to "personal" on fresh machines)
./main.sh setup work     # uses "work" profile (switches if different)
./main.sh setup work --skip-brew  # macOS: use "work" profile without Homebrew install/update/bundle
```

### Homebrew Packages (macOS only)

Each profile has its own complete Brewfile at `meta/homebrew/Brewfile.<profile>`. Core CLI tools are in both profiles; only genuinely profile-specific tools differ. During setup, only the matching profile's Brewfile is installed unless `--skip-brew` or `--skip-platform-packages` is passed. The `backup` command dumps the current machine's Homebrew state into the active profile's Brewfile:

```bash
./main.sh brew backup           # dumps to meta/homebrew/Brewfile.personal
./main.sh brew backup work      # dumps to meta/homebrew/Brewfile.work
```

### Adding a New Profile

1. Create `stow/git/profiles/<name>` with `[user]` name and email fields
2. **macOS only**: Create `meta/homebrew/Brewfile.<name>` with the desired packages
3. Run `./main.sh setup <name> --adopt` on first setup, or `./main.sh setup <name>` on normal reruns

## Agent Skills

[Agent Skills](https://agentskills.io/) are `SKILL.md` packages that give AI coding agents specialized domain knowledge. The setup script symlinks the `meta/skills/` directory so multiple tools discover them automatically:

| Tool | Discovery Path |
|------|---------------|
| **Claude Code** | `~/.claude/skills` |
| **Copilot CLI** | `~/.copilot/skills` |
| **Cursor IDE** | `~/.cursor/skills` |
| **Common Agent Path** | `~/.agents/skills` |

### Included Skills

| Skill | Purpose |
|-------|---------|
| `doc-coauthoring` | Structured workflow for co-authoring documentation |
| `dotfiles` | Expert guidance for managing this dotfiles repo |
| `skill-creator` | Create, modify, and evaluate agent skills |

To add a new skill, create a directory under `meta/skills/` containing a `SKILL.md` file. It will be picked up automatically without re-running setup.

## Shell Configuration

The `.zshrc` is a single loop that sources all files from `~/.zshrc.d/` — the same file-loop composition pattern used by the setup scripts. Files use numbered prefixes to control load order: `00-` runs first (p10k, PATH), `50-` is the default tier, and `99-` runs last (SDKMAN, zoxide). [Zinit](https://github.com/zdharma-continuum/zinit) is the plugin manager.

### Plugin Stack

| Plugin | Purpose |
|--------|---------|
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | Fast, customizable prompt theme |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Fish-like syntax highlighting |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | Additional completion definitions |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like autosuggestions from history |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | Replace default completion with fzf |
| OMZ `git` snippet | Git aliases and completions |
| OMZ `command-not-found` snippet | Suggests packages for unknown commands |

### Shell Integrations

- **fzf** — fuzzy finder for files, history, and completions
- **zoxide** — smarter `cd` that learns your most-used directories (aliased to `cd`, loaded via `99-zoxide.zsh`)
- **SDKMAN!** — JVM SDK version management (loaded via `99-sdkman.zsh`)

### Key Bindings

| Binding | Action |
|---------|--------|
| `Ctrl+P` | Search history backward |
| `Ctrl+N` | Search history forward |
| `Alt+W` | Kill region |

### Aliases

| Alias | Command |
|-------|---------|
| `ls` | `ls --color` |
| `vim` | `nvim` |
| `c` | `clear` |

## Tmux Configuration

Prefix is rebound to `Ctrl+A`. Vim-style navigation and copy mode are enabled.

### Key Bindings

| Binding | Action |
|---------|--------|
| `Prefix + \|` | Split pane horizontally |
| `Prefix + -` | Split pane vertically |
| `Prefix + r` | Reload tmux config |
| `Prefix + h/j/k/l` | Resize panes |
| `Prefix + m` | Toggle pane zoom |
| `v` (copy mode) | Begin selection |
| `y` (copy mode) | Copy selection |

### Plugins (via TPM)

| Plugin | Purpose |
|--------|---------|
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless navigation between tmux panes and Vim splits |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Persist sessions across restarts |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-save sessions every 15 minutes |
| [tmux-tokyo-night](https://github.com/fabioluciano/tmux-tokyo-night) | Tokyo Night color theme |

## Alacritty Configuration

Alacritty is configured with **JetBrains Mono Nerd Font** at size 16, block cursor, generous padding (25x20), and 256-color support. A library of 130+ color themes is included under `stow/alacritty/.config/alacritty/themes/` — uncomment an import line in `alacritty.toml` to switch themes.

URL hints are enabled with `Ctrl+Shift+U` for clickable links.

### Additional Configs in Alacritty Package

The alacritty stow package also includes:
- **LinearMouse** config (`.config/linearmouse/linearmouse.json`) — macOS mouse customization
- **Git ignore templates** (`.config/git/ignore`) — global git ignore patterns

## VS Code / Cursor Configuration

### Editor Settings

- **Font**: JetBrains Mono Nerd Font (editor and terminal)
- **Minimap**: Disabled
- **Tab size**: 2 spaces
- **Copilot**: Auto-completions and next-edit suggestions enabled
- **Formatters**: Prettier for JSON/YAML, yamlfmt for Docker Compose and GitHub Actions

### Custom Keybindings

| Binding | Context | Action |
|---------|---------|--------|
| `Shift+Enter` / `Ctrl+Enter` | Terminal | Send line continuation |
| `Ctrl+Shift+A` | Terminal | Focus next terminal |
| `Ctrl+Shift+B` | Terminal | Focus previous terminal |
| `Ctrl+Shift+J` | Global | Toggle bottom panel |
| `Ctrl+Shift+N` | Terminal | New terminal |
| `Ctrl+Shift+W` | Terminal | Kill terminal |
| `Ctrl+E` | Global | Toggle sidebar / focus file explorer |
| `N` | File explorer | New file |
| `Shift+N` | File explorer | New folder |
| `R` | File explorer | Rename file |
| `D` | File explorer | Delete file |

## Utility Commands

### `brew backup`

Dumps the current Homebrew state (formulae, casks, taps, VS Code extensions) into the active profile's Brewfile:

```bash
./main.sh brew backup           # dumps to meta/homebrew/Brewfile.personal
./main.sh brew backup work      # dumps to meta/homebrew/Brewfile.work
```

### `alacritty-icon`

Replaces the default Alacritty icon with a custom one from [macOSicons](https://macosicons.com/). Backs up the original icon before replacing.

```bash
./main.sh alacritty-icon
```

## Custom Shell Functions

### `link-skills` / `unlink-skills` — Project Skill Linking

Link a project's agent skills into the project-local discovery paths (`.claude/skills/`, `.agents/skills/`) without modifying dotfiles. Run from the repo root — the source directory is auto-discovered from common conventions:

| Priority | Path | Convention |
|----------|------|------------|
| 1 | `.ai-agent/skills/` | Generic agent skills |
| 2 | `.claude/skills/` | Claude Code |
| 3 | `.agents/skills/` | Generic agents |
| 4 | `.github/skills/` | GitHub ecosystem |
| 5 | `.copilot/skills/` | GitHub Copilot |

```bash
# From a project repo root — auto-discovers the skills directory
link-skills

# Explicit path
link-skills path/to/skills

# Remove only this project's skill links (global dotfiles skills untouched)
unlink-skills
```

`link-skills` creates relative per-skill symlinks within the project. `unlink-skills` uses `readlink` to only remove links it created.

### `gct` — Git Create Worktree

Creates a git worktree for a branch. If the branch exists on `origin`, it tracks the remote. Otherwise, it creates a new branch from `origin/main` and pushes it.

```bash
gct feature/my-branch
# Creates ../repo-name-feature-my-branch/ and cd's into it
```

### `grmt` — Git Remove Worktree

Removes a git worktree and returns to the main repo root. With no arguments, removes the worktree you're currently in.

```bash
grmt                    # remove current worktree
grmt /path/to/worktree  # remove specific worktree
```

## Adding New Configurations

### New tool installer

Create a single file — no existing scripts need editing:

```bash
# Cross-platform (must work on macOS + Linux without platform guards):
meta/scripts/install.d/shared/<NN>-toolname.sh

# Linux-only (apt-specific, Linux paths, etc.):
meta/scripts/install.d/linux/<NN>-toolname.sh
```

Template for `shared/`:
```bash
#!/bin/bash
# toolname — short description
command -v toolname &>/dev/null && return 0
[ -f "$HOME/.local/bin/toolname" ] && return 0  # fallback for ~/.local/bin installers
echo "Installing toolname..."
curl -fsSL https://toolname.dev/install.sh | bash
```

Template for npm tools in `shared/` (number ≥74):
```bash
#!/bin/bash
# toolname — short description
npm_install_global_if_needed toolname toolname toolname
```

Use `$SUDO`, `$ARCH_GO`, `$ARCH_MUSL` (set by `lib/`), `gh_latest_version OWNER REPO` (from `lib/github.sh`), and `npm_install_global_if_needed PACKAGE BINARY LABEL` (from `lib/npm.sh`) as needed. Never hardcode versions.

### New stow package

1. Create `stow/<tool>/` mirroring `$HOME` structure (e.g., `stow/neovim/.config/nvim/init.lua`)
2. Create `meta/scripts/stow.d/<NN>-tool.sh`:

```bash
#!/bin/bash
# tool — short description
stow_backup "$HOME/.toolrc"        # backs up real files, removes symlinks
stow_package tool                  # stows against $HOME by default
```

For non-`$HOME` targets (like claude or vscode), set `STOW_TARGET` before calling `stow_package`. For `--no-folding` packages, pass the flag directly: `stow_package tool --no-folding`.

3. Run `./main.sh setup --adopt` for first setup/adoption, or `./main.sh setup` to restow existing links.
