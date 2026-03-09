---
name: dotfiles
description: Guidance for managing the dotfiles repo — the single source of truth for shell, editor, git, and agent configurations. This skill is globally linked, so all changes that this repo is responsible for must target the dotfiles repo root, not local copies. Covers GNU Stow architecture, composition patterns, and high-traction areas: PATH, zsh utilities, keybindings, aliases, skills, stow packages, and install scripts. Use when the user asks to add, change, or debug dotfiles, shell, zsh, aliases.
---

# Dotfiles Management Skill

This skill encodes the conventions, architecture, and high-traction patterns for this dotfiles repo so changes are consistent, idempotent, and easy to maintain.

## Architecture at a Glance

- **GNU Stow** symlinks everything: `stow/<pkg>/` mirrors `$HOME`; `stow -d stow <pkg> -t $HOME --adopt` creates the links.
- **Composition pattern**: orchestrator scripts loop over files in a directory. Adding a feature = add one file, never edit the orchestrator.
- **Profiles** (`personal` / `work`): control git identity and macOS Brewfile. Auto-detected on re-runs via `lib/profile.sh`; pass explicitly only to switch.
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
| `meta/scripts/setup-common.sh` | SDKMAN!, stow.d loop, agent skills symlinks |
| `meta/scripts/stow.d/` | One `.sh` per stow package (git profile set in `50-git.sh`) |
| `meta/scripts/install.d/shared/` | CLI tool installers for Linux + Alpine |
| `meta/scripts/install.d/linux/` | Debian/Ubuntu-only installers |
| `meta/scripts/lib/` | Shared utilities: `arch.sh`, `sudo.sh`, `github.sh`, `profile.sh` |
| `meta/packages/linux.packages` | apt package list |
| `meta/packages/alpine.packages` | apk package list |
| `meta/homebrew/Brewfile.personal` | macOS personal Homebrew bundle |
| `meta/homebrew/Brewfile.work` | macOS work Homebrew bundle |

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

## Adding a New CLI Tool (Linux/Alpine)

Create `meta/scripts/install.d/shared/<NN>-toolname.sh` using alphabetical/numeric ordering:

```bash
#!/bin/bash
# toolname — one-line description
command -v toolname &>/dev/null && return 0
echo "Installing toolname..."
curl -fsSL https://install.example.com | bash
```

Rules:
- Use `return`, never `exit` (scripts are sourced)
- Guard with `command -v ... && return 0` for idempotency
- Use `$SUDO`, `$ARCH`, `$ARCH_GO`, `$ARCH_MUSL` from `lib/` — never hardcode
- Use `gh_latest_version OWNER REPO` from `lib/github.sh` for version detection

For macOS-only tools, add to the appropriate `Brewfile.<profile>` instead.

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

`link-skills` / `unlink-skills` in `utils-ai.zsh` are a separate concern — they handle **project-local** skill linking within a repo, not the global dotfiles skills.

`link-agent-md` in `utils-ai.zsh` ensures `AGENTS.md` is the canonical instructions file and `CLAUDE.md` is a symlink to it. If `CLAUDE.md` has the content, it migrates it to `AGENTS.md` and creates the symlink. Run from the project root — no arguments needed.

## Conventions Checklist

- [ ] `install.d/` scripts use `return`, not `exit`
- [ ] `install.d/` scripts guard with `command -v tool &>/dev/null && return 0`
- [ ] New zsh config goes in its own `.zshrc.d/` file, not appended to `.zshrc`
- [ ] Path entries go in `00-path.zsh` only
- [ ] Numbered prefixes control load order: `00-` first, `50-` default, `99-` last — new files default to `50-`
- [ ] Device-specific configs inside `stow/alacritty/.config/` (non-`alacritty/`) are gitignored
- [ ] `stow/git/.gitconfig-profile` is gitignored — never commit it
- [ ] `backup/` is for timestamped pre-existing config snapshots — never edit these

## Debugging Stow Conflicts

If stow fails with a conflict:
```bash
stow -d stow <pkg> -t "$HOME" --adopt -n  # dry run
```
The `--adopt` flag moves conflicting real files into the repo and symlinks them. If the conflict is a `.DS_Store`, `setup-common.sh` auto-cleans them before stowing.
