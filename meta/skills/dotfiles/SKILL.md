---
name: dotfiles
description: Guidance for managing the dotfiles repo — the single source of truth for shell, editor, git, and agent configurations. This skill is globally linked, so all changes that this repo is responsible for must target the dotfiles repo root, not local copies. Covers GNU Stow architecture, composition patterns, and high-traction areas - PATH, zsh utilities, keybindings, aliases, skills, stow packages, and install scripts. Use when the user asks to add, change, or debug dotfiles, shell, zsh, aliases.
---

# Dotfiles Management Skill

This skill encodes the conventions, architecture, and high-traction patterns for this dotfiles repo so changes are consistent, idempotent, and easy to maintain.

## Architecture at a Glance

- **GNU Stow** symlinks everything: `stow/<pkg>/` mirrors `$HOME`; `stow -d stow <pkg> -t $HOME --adopt` creates the links.
- **Composition pattern**: orchestrator scripts loop over files in a directory. Adding a feature = add one file, never edit the orchestrator.
- **Profiles** (`personal` / `work`): control git identity and macOS Brewfile. Auto-detected on re-runs via `lib/profile.sh`; pass explicitly only to switch.
- **Two platforms**: macOS and Linux (Debian/Ubuntu). Both follow an identical script structure that converges on `setup-common.sh`.
- **`main.sh`** is the single entrypoint — sources scripts, never runs them as subprocesses.
- **`AGENTS.md`** is the project instructions file. `CLAUDE.md` is a symlink to it for Claude Code compatibility.

## High-Traction Files

| File | What lives here |
|------|----------------|
| `stow/zsh/.zshrc.d/00-p10k.zsh` | Powerlevel10k instant prompt (must load first) |
| `stow/zsh/.zshrc.d/00-path.zsh` | All `$PATH` exports, tool-specific path entries |
| `stow/zsh/.zshrc.d/50-aliases.zsh` | Shell aliases |
| `stow/zsh/.zshrc.d/50-keybindings.zsh` | Zsh keybindings (`bindkey`) |
| `stow/zsh/.zshrc.d/50-utils-ai.zsh` | `link-skills`, `unlink-skills` (project-local skill linking), `link-agent-md` (ensure AGENTS.md is canonical, CLAUDE.md symlinks to it) |
| `stow/zsh/.zshrc.d/50-utils-worktree.zsh` | Git worktree helpers (`gct`, `grmt`) |
| `stow/zsh/.zshrc.d/50-integrations.zsh` | Tool integrations (fzf, etc.) |
| `stow/zsh/.zshrc.d/50-zinit.zsh` | Zinit plugin manager + plugins + compinit |
| `stow/zsh/.zshrc.d/99-sdkman.zsh` | SDKMAN init (must load last) |
| `stow/zsh/.zshrc.d/99-zoxide.zsh` | zoxide init (must load after compinit) |
| `stow/bin/.local/bin/hcli` | Thin wrapper — discovers homelab repo and delegates to `uv run hcli` |
| `meta/scripts/setup-common.sh` | SDKMAN!, stow.d loop, agent skills symlinks |
| `meta/scripts/stow.d/` | One `.sh` per stow package (git profile set in `50-git.sh`) |
| `meta/scripts/install.d/shared/` | Cross-platform tool installers (must work on macOS + Linux without platform guards) |
| `meta/scripts/install.d/linux/` | Linux-only installers (apt-specific, Linux paths, etc.) |
| `meta/scripts/lib/` | Shared utilities: `arch.sh`, `sudo.sh`, `github.sh`, `profile.sh` |
| `meta/packages/linux.packages` | apt package list |
| `meta/homebrew/Brewfile.personal` | macOS personal Homebrew bundle |
| `meta/homebrew/Brewfile.work` | macOS work Homebrew bundle |

## Cross-Platform Install Architecture

Both platform scripts follow the same structure:

```
DOTFILES_DIR → LIB → INSTALL_D → source profile.sh → resolve + validate profile
→ source sudo.sh → source arch.sh → source github.sh
→ platform packages (brew bundle / apt-get)
→ install.d loop → setup-common.sh
```

**`shared/` scripts must work on both macOS and Linux without platform guards.** No Darwin checks, no `apt-get` checks, no platform-specific conditionals in guards. If a script would fail on macOS, it belongs in `linux/`. Inline OS detection for binary download URLs (e.g. `[[ "$(uname)" == "Darwin" ]] && OS="darwin"`) is fine — that's selecting the right binary, not guarding execution.

**macOS**: `brew bundle` runs first, so most shared scripts hit their `command -v` guard and skip.
**Linux**: `shared/` and `linux/` scripts are **merged and sorted by filename** so numbering controls global install order (e.g. `linux/70-node` runs before `shared/80-vercel`).

### Script numbering

Scripts across both directories share a single number line:

| Range | Purpose | Examples |
|-------|---------|----------|
| 10–40 | Standalone tools (no deps) | lazygit, zoxide, yq, uv |
| 50–60 | Linux-specific standalone tools | nerd-fonts, docker-compose, tailscale |
| 70–72 | Node.js ecosystem setup | node (linux), nvm (linux) |
| 74–76 | Package managers depending on node | pnpm, agent-browser |
| 80–90 | npm-installed CLIs (require npm prerequisite guard) | vercel, gemini-cli |
| 95–99 | Late installers | opencode, claude |

### Idempotency patterns for `install.d/` scripts

Every script must be safe to re-run. Use the appropriate guard:

| Pattern | When to use | Where |
|---------|-------------|-------|
| `command -v tool && return 0` | Standard — tool has a binary on PATH | `shared/` and `linux/` |
| `[ -f "$HOME/.local/bin/tool" ] && return 0` | Fallback — tool installs to `~/.local/bin` which isn't on PATH in non-interactive bash | `shared/` (after `command -v`) |
| `[ -s "$HOME/.nvm/nvm.sh" ] && return 0` | Shell function, not a binary | `linux/` (nvm) |
| Marker files (`.installed-Name-vX.Y.Z`) | No binary to check, versioned assets | `linux/` (nerd-fonts) |
| `command -v npm \|\| { echo "Skipped..."; return 0; }` | Prerequisite guard — npm must be available | `shared/` (npm tools) |

**`shared/` scripts use only `command -v` guards (+ fallback path checks + prerequisite guards).** No Darwin checks, no `apt-get` checks. If a script needs those, it belongs in `linux/`.

### npm-installed tools pattern

For tools installed via `npm install -g`, use this template (number ≥74):

```bash
#!/bin/bash
# toolname — short description
command -v toolname &>/dev/null && return 0
command -v npm &>/dev/null || { echo "  Skipped toolname (npm not found)"; return 0; }
echo "Installing toolname..."
# Avoid unnecessary sudo when npm global prefix is user-writable (e.g. Homebrew node)
NPM_PREFIX="$(npm prefix -g 2>/dev/null)"
if [[ -w "$NPM_PREFIX" ]]; then
  npm install -g toolname
else
  $SUDO npm install -g toolname
fi
```

npm tools must be numbered ≥74 so they run after `linux/70-node` installs Node.js on Linux. On macOS, brew provides node before the shared loop runs.

### Cross-platform binary downloads

For tools downloaded as platform-specific binaries, detect the OS within the script:

```bash
TOOL_OS="linux"
[[ "$(uname)" == "Darwin" ]] && TOOL_OS="darwin"
```

Use `$ARCH_GO` (amd64/arm64) and `$ARCH_MUSL` (x86_64/aarch64) from `lib/arch.sh` — never hardcode architecture. `arch.sh` handles both Linux `aarch64` and macOS `arm64`. Always verify the release asset naming convention of the upstream project — naming varies (e.g. lazygit uses `arm64` even on Linux, not `aarch64`).

### Version detection

Never hardcode tool versions. Use `gh_latest_version OWNER REPO` from `lib/github.sh` to fetch the latest release tag. Always handle the failure case:

```bash
VERSION="$(gh_latest_version owner repo)"
if [[ -z "$VERSION" ]]; then
  echo "  Warning: could not determine version, skipping." >&2
  return 0
fi
```

## .zshrc.d Numbered Prefix Convention

All `.zshrc.d/` files use a numbered prefix to control load order. `.zshrc` is just a 3-line loop — all config lives in the `.d/` files.

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `00-` | Must run first | `00-p10k.zsh` (instant prompt), `00-path.zsh` (PATH) |
| `50-` | Default tier, no ordering constraint | `50-aliases.zsh`, `50-zinit.zsh`, `50-keybindings.zsh` |
| `99-` | Must run last | `99-sdkman.zsh` (SDKMAN), `99-zoxide.zsh` (after compinit) |

New `.zshrc.d/` files should use the `50-` prefix unless they have a specific ordering requirement.

## PATH Changes

All PATH manipulation goes in `stow/zsh/.zshrc.d/00-path.zsh`. The `00-` prefix ensures it loads before other modules that might rely on newly-added tools.

Pattern:
```zsh
export PATH="$HOME/.new-tool/bin:$PATH"
```

Never scatter `export PATH=` into other `.zshrc.d/` files — keep it centralized.

## Adding a Keybinding

Edit `stow/zsh/.zshrc.d/50-keybindings.zsh`. Use `bindkey` with explicit key sequences. Document non-obvious sequences with a comment.

```zsh
bindkey '^P' history-search-backward   # Ctrl+P: history search up
```

## Adding an Alias

Edit `stow/zsh/.zshrc.d/50-aliases.zsh`. Group by topic with a comment header.

## Adding a Utility Function

Add to the appropriate `50-utils-*.zsh` file, or create `stow/zsh/.zshrc.d/50-utils-<topic>.zsh` for a new domain. `.zshrc` auto-sources all `~/.zshrc.d/*.zsh` files.

## Adding a New CLI Tool

Create `meta/scripts/install.d/shared/<NN>-toolname.sh` (cross-platform) or `meta/scripts/install.d/linux/<NN>-toolname.sh` (Linux only):

```bash
#!/bin/bash
# toolname — one-line description
command -v toolname &>/dev/null && return 0
[ -f "$HOME/.local/bin/toolname" ] && return 0  # fallback for ~/.local/bin installers
echo "Installing toolname..."
curl -fsSL https://install.example.com | bash
```

Rules:
- Use `return`, never `exit` (scripts are sourced)
- Guard with `command -v ... && return 0` for idempotency
- Add fallback path check for tools that install to `~/.local/bin` (not on PATH in non-interactive bash)
- Use `$SUDO`, `$ARCH`, `$ARCH_GO`, `$ARCH_MUSL` from `lib/` — never hardcode
- Use `gh_latest_version OWNER REPO` from `lib/github.sh` — never hardcode versions
- **`shared/` scripts must not contain Darwin guards, `apt-get` guards, or any platform-specific conditionals in their guards** — if a script needs those, put it in `linux/`
- npm-dependent tools go in `shared/` (npm works cross-platform) but must be numbered ≥74
- Linux-specific install methods (apt, Linux font paths, shell functions without a binary) go in `linux/`

For macOS-only tools, add to **both** `Brewfile.personal` and `Brewfile.work` unless genuinely profile-specific.

## Adding a New Stow Package

1. Create `stow/<tool>/` mirroring the `$HOME` structure
2. Create `meta/scripts/stow.d/<NN>-tool.sh`:

```bash
#!/bin/bash
# tool — short description
stow_backup "$HOME/.toolrc"
stow_package tool
```

- `stow_backup`: backs up real files, silently removes symlinks
- `stow_package`: runs stow against `$STOW_TARGET` (defaults to `$HOME`)
- Set `STOW_TARGET` before calling `stow_package` for non-`$HOME` targets (e.g., claude, vscode)

## Agent Skills

Global skills live in `meta/skills/`. During setup, this directory is symlinked to multiple tool-specific locations:

- `~/.copilot/skills`
- `~/.cursor/skills`
- `~/.agents/skills`
- `~/.claude/skills`

The symlink targets are defined in `meta/scripts/setup-common.sh` (the `for target in ...` loop). Adding a new skill directory under `meta/skills/` is picked up automatically — no re-run needed since the whole directory is symlinked.

`link-skills` / `unlink-skills` in `utils-ai.zsh` are a separate concern — they handle **project-local** skill linking within a repo, not the global dotfiles skills. This should only be manually invoked by the user when they want to link/unlink skills in a specific project directory.

`link-agent-md` in `utils-ai.zsh` ensures `AGENTS.md` is the canonical instructions file and `CLAUDE.md` is a symlink to it. If `CLAUDE.md` has the content, it migrates it to `AGENTS.md` and creates the symlink. Run from the project root — no arguments needed.

## Conventions Checklist

- [ ] `install.d/` scripts use `return`, not `exit`
- [ ] `install.d/` scripts guard with `command -v tool &>/dev/null && return 0`
- [ ] `~/.local/bin` installers add fallback: `[ -f "$HOME/.local/bin/tool" ] && return 0`
- [ ] `shared/` scripts contain no Darwin guards, apt-get guards, or platform conditionals in guards
- [ ] Scripts needing platform-specific guards (Darwin checks, apt-get checks, marker files) are in `linux/`
- [ ] npm-dependent scripts in `shared/` include prerequisite guard and are numbered ≥74
- [ ] Cross-platform binary scripts detect OS inline (`uname`) and use `$ARCH_GO`/`$ARCH_MUSL` — never hardcode
- [ ] Versions are fetched dynamically via `gh_latest_version` — never hardcoded
- [ ] Core CLI tools are in both Brewfile.personal and Brewfile.work (not profile-specific unless genuinely different)
- [ ] New zsh config goes in its own `.zshrc.d/` file, not appended to `.zshrc`
- [ ] Path entries go in `00-path.zsh` only
- [ ] Numbered prefixes control load order: `00-` first, `50-` default, `99-` last — new files default to `50-`
- [ ] Device-specific configs inside `stow/alacritty/.config/` (non-`alacritty/`) are gitignored
- [ ] `stow/git/.gitconfig-profile` is gitignored — never commit it
- [ ] `backup/` is for timestamped pre-existing config snapshots — never edit these
- [ ] Adding a new file to an existing stow package requires re-running stow/setup (`--adopt` prevents tree folding)

## Stow `--adopt` and Tree Folding

Stow's `--adopt` flag and tree folding (directory-level symlinks) are mutually exclusive. With `--adopt`, stow pulls pre-existing files into the repo and creates **per-file symlinks**, so the parent directory remains a real directory. This means adding a new file to a stow package in the repo (e.g., a new `.zshrc.d/*.zsh` file) won't appear at the target until you re-run stow or setup. This is a deliberate tradeoff — `--adopt` protects pre-existing configs from being overwritten.

## Debugging Stow Conflicts

If stow fails with a conflict:
```bash
stow -d stow <pkg> -t "$HOME" --adopt -n  # dry run
```
The `--adopt` flag moves conflicting real files into the repo and symlinks them. If the conflict is a `.DS_Store`, `setup-common.sh` auto-cleans them before stowing.
