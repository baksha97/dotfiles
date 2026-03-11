# Dotfiles

Personal development environment managed with [GNU Stow](https://www.gnu.org/software/stow/) and driven through a single `main.sh` entrypoint. One command bootstraps a fresh macOS, Linux (Debian/Ubuntu), or Alpine machine with shell, editor, terminal, git, and AI agent skill configurations.

## Table of Contents

- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
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
./main.sh setup          # full setup (auto-detects profile, defaults to "personal")
./main.sh setup work     # full setup with "work" profile
```

### All Commands

```bash
./main.sh setup [profile]        # bootstrap the system (auto-detects OS and profile on re-run)
./main.sh brew backup [profile]  # dump current Homebrew state to Brewfile.<profile>
./main.sh alacritty-icon         # replace the Alacritty app icon
```

## How It Works

This repository uses **GNU Stow** to manage dotfiles. Each directory inside `stow/` is a "stow package" whose internal structure mirrors where the files should live relative to `$HOME`. Stow creates symlinks from your home directory into this repo, so every config file is version-controlled in one place.

The `--adopt` flag is used during setup, which means if you already have a config file at the target location, Stow moves it into the repo (adopting it) and creates the symlink. After running setup, a `git diff` will show any differences between your existing configs and the repo versions.

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

- `meta/scripts/install.d/shared/` — tool installers for all Linux-family platforms
- `meta/scripts/install.d/linux/` — Debian/Ubuntu-only tools
- `meta/scripts/install.d/linux-gui/` — GUI apps (headful only)
- `meta/scripts/stow.d/` — one stow manifest per package

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
    │   ├── linux.packages          # apt packages for Debian/Ubuntu setup
    │   └── alpine.packages         # apk packages for Alpine setup
    └── scripts/                    # Implementation scripts
        ├── lib/                    # Shared utilities (sourced first by platform scripts)
        │   ├── arch.sh             # ARCH_GO / ARCH_MUSL detection
        │   ├── sudo.sh             # SUDO prefix detection
        │   ├── github.sh           # gh_latest_version() helper
        │   └── profile.sh          # resolve_profile() — auto-detect or accept explicit
        ├── install.d/              # Per-tool installers (one file = one tool)
        │   ├── shared/             # Tools for all Linux-family platforms
        │   ├── linux/              # Debian/Ubuntu-only tools
        │   └── linux-gui/          # GUI apps (headful environments only)
        ├── stow.d/                 # Per-package stow manifests (one file = one package)
        ├── setup-macos.sh          # macOS bootstrap (Homebrew)
        ├── setup-linux.sh          # Linux bootstrap orchestrator
        ├── setup-alpine.sh         # Alpine bootstrap orchestrator
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
2. **Show hidden files** in Finder (macOS) or Nautilus (Linux)
3. **Platform-specific package installation:**
   - **macOS**: Install Homebrew (if missing), then install from `meta/homebrew/Brewfile.<profile>`
   - **Linux**: Install apt packages from `meta/packages/linux.packages`, then source each tool installer in `install.d/`
   - **Alpine**: Install apk packages from `meta/packages/alpine.packages`, then source shared tool installers
4. **Install SDKMAN!** for JVM SDK management
5. **Stow all packages** — each `stow.d/` script backs up and links one package
6. **Set git profile** — copies the chosen identity into `~/.gitconfig-profile`
7. **Symlink Agent Skills** — makes skills discoverable by Copilot, Cursor, and other agents
8. **Linux SDKMAN packages** — installs Gradle and Kotlin (Linux only)

### macOS Brewfile Highlights

| Category | Packages |
|----------|----------|
| **CLI tools** | `fzf`, `zoxide`, `tmux`, `stow`, `curl`, `ffmpeg`, `typos-cli` |
| **Containers** | `docker`, `colima`, `act` (local GitHub Actions) |
| **Fonts** | JetBrains Mono, Fira Code, Mononoki, Roboto Mono, and more (all Nerd Font variants) |
| **Apps** | Alacritty, VS Code, Google Chrome, Rectangle, Spotify, Multipass |
| **VS Code extensions** | Copilot, Vim, Docker, Python, TOML, GitHub Actions |

### Linux Installation Details

**apt packages** (`meta/packages/linux.packages`):
- Core: `git`, `git-lfs`, `curl`, `zsh`, `tmux`, `stow`, `fzf`, `jq`
- Media: `ffmpeg`, `scrcpy`
- Tools: `rclone`, `aria2`, `ansible`, `exiftool`
- Utilities: `fontconfig`, `unzip`, `zip`, `ca-certificates`

**Shared tools** (`install.d/shared/` — also installed on Alpine):
- `lazygit`, `zoxide`, `yq`, `uv`
- **Nerd Fonts**: DroidSansMono, FiraCode, JetBrainsMono, Meslo, Mononoki, RobotoMono, SourceCodePro, SymbolsOnly

**Linux-only tools** (`install.d/linux/`):
- `gh` CLI, `fzf` (latest from GitHub), `just`, `docker`, `docker-compose` plugin
- `tailscale`, `nodejs` LTS, `vercel`, `gemini-cli`, `opencode`, `claude`

**GUI apps** (`install.d/linux-gui/` — headful environments only):
- VS Code, VS Code Insiders, Google Chrome (amd64 only), Firefox, VLC, Alacritty, Android Studio

### Alpine Installation Details

**apk packages** (`meta/packages/alpine.packages`): `git`, `curl`, `zsh`, `tmux`, `fzf`, `jq`, `rclone`, `aria2`, `ffmpeg`, and more.

**Shared tools** (`install.d/shared/`): same as Linux shared tools above.

## Profiles

Profiles control git identity and (on macOS) which Homebrew packages are installed. Linux and Alpine use the same package lists regardless of profile.

On re-runs, the active profile is auto-detected by comparing `.gitconfig-profile` against `stow/git/profiles/*`. Pass a profile name explicitly only to switch profiles. Fresh machines default to `personal`.

Available profiles:
- `personal` — Full macOS setup with GUI apps
- `work` — Work environment setup

```bash
./main.sh setup          # auto-detects profile (defaults to "personal" on fresh machines)
./main.sh setup work     # uses "work" profile (switches if different)
```

### Homebrew Packages (macOS only)

Each profile has its own complete Brewfile at `meta/homebrew/Brewfile.<profile>`. During setup, only the matching profile's Brewfile is installed. The `backup` command dumps the current machine's Homebrew state into the active profile's Brewfile:

```bash
./main.sh brew backup           # dumps to meta/homebrew/Brewfile.personal
./main.sh brew backup work      # dumps to meta/homebrew/Brewfile.work
```

### Adding a New Profile

1. Create `stow/git/profiles/<name>` with `[user]` name and email fields
2. **macOS only**: Create `meta/homebrew/Brewfile.<name>` with the desired packages
3. Run `./main.sh setup <name>`

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
| `my-voice` | Internal communications in Travis's voice |
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
# For a tool available on all Linux-family platforms:
meta/scripts/install.d/shared/<NN>-toolname.sh

# For a Linux-only tool:
meta/scripts/install.d/linux/<NN>-toolname.sh
```

Template:
```bash
#!/bin/bash
# toolname — short description
command -v toolname &>/dev/null && return 0
echo "Installing toolname..."
curl -fsSL https://toolname.dev/install.sh | bash
```

Use `$SUDO`, `$ARCH_GO`, `$ARCH_MUSL` (set by `lib/`) and `gh_latest_version OWNER REPO` (from `lib/github.sh`) as needed.

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

3. Run `./main.sh setup` or manually run the stow command.
