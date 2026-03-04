<img width="1297" alt="image" src="https://github.com/baksha97/dotfiles/assets/15055008/39871f8c-fd15-46df-a5c9-f7dcc3bd9e35">

# Dotfiles

Personal development environment managed with [GNU Stow](https://www.gnu.org/software/stow/) and automated via a single `setup.sh` script. One command bootstraps a fresh macOS (or Linux) machine with shell, editor, terminal, git, and AI agent skill configurations.

## Table of Contents

- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Repository Structure](#repository-structure)
- [Stow Packages](#stow-packages)
- [What Gets Installed](#what-gets-installed)
- [Git Profile Selection](#git-profile-selection)
- [Agent Skills](#agent-skills)
- [Shell Configuration](#shell-configuration)
- [Tmux Configuration](#tmux-configuration)
- [Alacritty Configuration](#alacritty-configuration)
- [VS Code / Cursor Configuration](#vs-code--cursor-configuration)
- [Utility Scripts](#utility-scripts)
- [Custom Shell Functions](#custom-shell-functions)
- [Adding New Configurations](#adding-new-configurations)

## Quick Start

```bash
git clone git@github.com:baksha97/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh          # defaults to "personal" git profile
./setup.sh work     # use a specific profile directly
```

## How It Works

This repository uses **GNU Stow** to manage dotfiles. Each top-level directory is a "stow package" whose internal structure mirrors where the files should live relative to `$HOME`. When you run `stow <package> -t "$HOME"`, Stow creates symlinks from your home directory into this repo, so every config file is version-controlled in one place.

The `--adopt` flag is used during setup, which means if you already have a config file at the target location, Stow moves it into the repo (adopting it) and creates the symlink. After running setup, a `git diff` will show any differences between your existing configs and the repo versions.

```
dotfiles/
├── zsh/
│   └── .zshrc              →  ~/.zshrc
├── tmux/
│   └── .tmux.conf          →  ~/.tmux.conf
├── git/
│   ├── .gitconfig          →  ~/.gitconfig
│   └── .gitignore          →  ~/.gitignore
├── alacritty/
│   └── .config/alacritty/  →  ~/.config/alacritty/
└── ...
```

## Repository Structure

```
dotfiles/
├── agent-skills/          # AI coding agent skill packages
│   └── skills/
│       ├── android-coroutines/
│       ├── android-emulator-skill/
│       ├── android-gradle-logic/
│       ├── gradle-build-performance/
│       └── kotlin-concurrency-expert/
├── alacritty/             # Alacritty terminal emulator config
│   └── .config/alacritty/
│       ├── alacritty.toml
│       └── themes/        # 130+ color themes
├── git/                   # Git config and profiles
│   ├── .gitconfig
│   ├── .gitignore         # Global gitignore
│   └── profiles/
│       ├── personal       # Name + email for personal projects
│       └── work           # Name + email for work projects
├── powerlevel10k/         # Powerlevel10k prompt theme
│   └── .p10k.zsh
├── tmux/                  # tmux terminal multiplexer config
│   └── .tmux.conf
├── vscode/                # VS Code / Cursor editor settings
│   ├── settings.json
│   ├── keybindings.json
│   └── .vscode/extensions/
├── zsh/                   # Zsh shell config
│   └── .zshrc
├── Brewfile               # Homebrew packages, casks, and VS Code extensions
├── Brewfile.lock.json     # Locked dependency versions
├── setup.sh               # Main bootstrap script
├── backup.sh              # Dumps current Homebrew state to Brewfile
└── change-alacritty-icon.sh  # Replaces Alacritty app icon
```

## Stow Packages

Each directory is a self-contained stow package. The table below shows where each package's files end up:

| Package | Contents | Symlink Target |
|---------|----------|----------------|
| `zsh` | `.zshrc` | `$HOME` |
| `powerlevel10k` | `.p10k.zsh` | `$HOME` |
| `tmux` | `.tmux.conf` | `$HOME` |
| `alacritty` | `.config/alacritty/` | `$HOME` |
| `git` | `.gitconfig`, `.gitignore` | `$HOME` |
| `vscode` | `settings.json`, `keybindings.json`, extensions | Platform-specific VS Code `User/` directory |

VS Code target paths:
- **macOS**: `~/Library/Application Support/Code/User`
- **Linux**: `~/.config/Code/User`

## What Gets Installed

The `setup.sh` script performs these steps in order:

1. **Show hidden files** in Finder (macOS) or Nautilus (Linux)
2. **Install Homebrew** if not present
3. **Install all Brewfile packages** — CLI tools, casks, fonts, and VS Code extensions
4. **Install SDKMAN!** for JVM SDK management
5. **Stow all packages** — creates symlinks for zsh, powerlevel10k, tmux, alacritty, vscode, and git
6. **Select a git profile** — copies the chosen identity into `~/.gitconfig-profile`
7. **Symlink Agent Skills** — makes skills discoverable by Copilot and Cursor

### Brewfile Highlights

| Category | Packages |
|----------|----------|
| **CLI tools** | `fzf`, `zoxide`, `tmux`, `stow`, `curl`, `ffmpeg`, `typos-cli` |
| **Containers** | `docker`, `colima`, `act` (local GitHub Actions) |
| **Fonts** | JetBrains Mono, Fira Code, Mononoki, Roboto Mono, and more (all Nerd Font variants) |
| **Apps** | Alacritty, VS Code, Google Chrome, Rectangle, Spotify, Multipass |
| **VS Code extensions** | Copilot, Vim, Docker, Python, TOML, GitHub Actions |

## Git Profile Selection

Git identity is managed through swappable profiles stored in `git/profiles/`. Running `./setup.sh` defaults to the `personal` profile. Pass a profile name to use a different one:

```bash
./setup.sh          # uses "personal"
./setup.sh work     # uses "work"
```

The selected profile is copied to `git/.gitconfig-profile`, which is included by `.gitconfig` via:

```ini
[include]
    path = ~/.gitconfig-profile
```

The `.gitconfig-profile` file is gitignored so your active identity stays local. To add a new profile, create a file under `git/profiles/` with `[user]` name and email fields.

## Agent Skills

[Agent Skills](https://agentskills.io/) are `SKILL.md` packages that give AI coding agents specialized domain knowledge. The setup script symlinks the `agent-skills/skills/` directory so multiple tools discover them automatically:

| Tool | Discovery Path |
|------|---------------|
| **Copilot CLI** | `~/.copilot/skills` |
| **Cursor IDE** | `~/.cursor/skills` |

### Included Skills

| Skill | Purpose |
|-------|---------|
| `android-coroutines` | Kotlin Coroutines patterns for Android |
| `android-emulator-skill` | Android build, test, and emulator automation |
| `android-gradle-logic` | Convention Plugins and Version Catalogs |
| `gradle-build-performance` | Build performance debugging and optimization |
| `kotlin-concurrency-expert` | Coroutine review and thread safety remediation |

To add a new skill, create a directory under `agent-skills/skills/` containing a `SKILL.md` file. It will be picked up automatically without re-running setup.

## Shell Configuration

The `.zshrc` sets up a modern Zsh environment using [Zinit](https://github.com/zdharma-continuum/zinit) as the plugin manager.

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
- **zoxide** — smarter `cd` that learns your most-used directories (aliased to `cd`)
- **SDKMAN!** — JVM SDK version management (loaded at end of `.zshrc`)

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

Alacritty is configured with **JetBrains Mono Nerd Font** at size 16, block cursor, generous padding (25x20), and 256-color support. A library of 130+ color themes is included under `alacritty/.config/alacritty/themes/` — uncomment an import line in `alacritty.toml` to switch themes.

URL hints are enabled with `Ctrl+Shift+U` for clickable links.

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

## Utility Scripts

### `backup.sh`

Dumps the current Homebrew state (formulae, casks, taps, VS Code extensions) into the `Brewfile`:

```bash
./backup.sh
```

### `change-alacritty-icon.sh`

Replaces the default Alacritty icon with a custom one from [macOSicons](https://macosicons.com/). Backs up the original icon before replacing.

```bash
./change-alacritty-icon.sh
```

## Custom Shell Functions

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

To add a new tool's config to this repo:

1. Create a new directory at the repo root named after the tool (e.g., `neovim/`)
2. Mirror the directory structure relative to `$HOME` inside it (e.g., `neovim/.config/nvim/init.lua`)
3. Add a `stow` command to `setup.sh`:
   ```bash
   stow neovim -t "$HOME" --adopt
   ```
4. Run `setup.sh` or manually run the stow command to create the symlinks
