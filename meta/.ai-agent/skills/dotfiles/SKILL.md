---
name: dotfiles
description: Expert guidance for managing and evolving this dotfiles repo. Covers the GNU Stow architecture, composition patterns, and the high-traction areas most likely to need updates: PATH configuration, zsh utilities, keybindings, aliases, skills symlinks, stow packages, and install scripts. Use when the user asks to add, change, or debug anything in this dotfiles repo.
---

# Dotfiles Management Skill

This skill encodes the conventions, architecture, and high-traction patterns for this dotfiles repo so changes are consistent, idempotent, and easy to maintain.

## Architecture at a Glance

- **GNU Stow** symlinks everything: `stow/<pkg>/` mirrors `$HOME`; `stow -d stow <pkg> -t $HOME --adopt` creates the links.
- **Composition pattern**: orchestrator scripts loop over files in a directory. Adding a feature = add one file, never edit the orchestrator.
- **Profiles** (`personal` / `work`): control git identity and macOS Brewfile only.
- **`main.sh`** is the single entrypoint — sources scripts, never runs them as subprocesses.

## High-Traction Files

| File | What lives here |
|------|----------------|
| `stow/zsh/.zshrc.d/00-path.zsh` | All `$PATH` exports, tool-specific path entries |
| `stow/zsh/.zshrc.d/aliases.zsh` | Shell aliases |
| `stow/zsh/.zshrc.d/keybindings.zsh` | Zsh keybindings (`bindkey`) |
| `stow/zsh/.zshrc.d/utils-ai.zsh` | `link-skills`, `unlink-skills`, `_find-skills-src` |
| `stow/zsh/.zshrc.d/utils-worktree.zsh` | Git worktree helpers |
| `stow/zsh/.zshrc.d/integrations.zsh` | Tool integrations (zoxide, fzf, etc.) |
| `stow/zsh/.zshrc.d/zinit.zsh` | Zinit plugin manager + plugins |
| `meta/scripts/setup-common.sh` | SDKMAN!, stow.d loop, git profile, agent skills symlinks |
| `meta/scripts/stow.d/` | One `.sh` per stow package |
| `meta/scripts/install.d/shared/` | CLI tool installers for Linux + Alpine |
| `meta/scripts/install.d/linux/` | Debian/Ubuntu-only installers |
| `meta/scripts/lib/` | Shared utilities: `arch.sh`, `sudo.sh`, `github.sh` |
| `meta/packages/linux.packages` | apt package list |
| `meta/packages/alpine.packages` | apk package list |
| `meta/homebrew/Brewfile.personal` | macOS personal Homebrew bundle |
| `meta/homebrew/Brewfile.work` | macOS work Homebrew bundle |

## PATH Changes

All PATH manipulation goes in `stow/zsh/.zshrc.d/00-path.zsh`. The `00-` prefix ensures it loads before other modules that might rely on newly-added tools.

Pattern:
```zsh
export PATH="$HOME/.new-tool/bin:$PATH"
```

Never scatter `export PATH=` into other `.zshrc.d/` files — keep it centralized.

## Adding a Keybinding

Edit `stow/zsh/.zshrc.d/keybindings.zsh`. Use `bindkey` with explicit key sequences. Document non-obvious sequences with a comment.

```zsh
bindkey '^P' history-search-backward   # Ctrl+P: history search up
```

## Adding an Alias

Edit `stow/zsh/.zshrc.d/aliases.zsh`. Group by topic with a comment header.

## Adding a Utility Function

Add to the appropriate `utils-*.zsh` file, or create `stow/zsh/.zshrc.d/utils-<topic>.zsh` for a new domain. `.zshrc` auto-sources all `~/.zshrc.d/*.zsh` files.

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
- Set `STOW_TARGET` before calling `stow_package` for non-`$HOME` targets (e.g., VSCode)

## Agent Skills Symlinks

Skills in `meta/.ai-agent/skills/` are symlinked to multiple targets during setup. **All four locations must stay in sync** whenever adding a new target:

1. `meta/scripts/setup-common.sh` — the `for target in ...` loop (global whole-dir symlink)
2. `stow/zsh/.zshrc.d/utils-ai.zsh` — `bases` array in `link-skills` (per-skill symlinks)
3. `stow/zsh/.zshrc.d/utils-ai.zsh` — `bases` array in `unlink-skills`

Current targets: `~/.copilot/skills`, `~/.cursor/skills`, `~/.agents/skills`, `~/.claude/skills`

## Conventions Checklist

- [ ] `install.d/` scripts use `return`, not `exit`
- [ ] `install.d/` scripts guard with `command -v tool &>/dev/null && return 0`
- [ ] New zsh config goes in its own `.zshrc.d/` file, not appended to `.zshrc`
- [ ] Path entries go in `00-path.zsh` only
- [ ] Numbered prefixes (`NN-`) control load order — lower = earlier
- [ ] Device-specific configs inside `stow/alacritty/.config/` (non-`alacritty/`) are gitignored
- [ ] `stow/git/.gitconfig-profile` is gitignored — never commit it
- [ ] `backup/` is for timestamped pre-existing config snapshots — never edit these

## Debugging Stow Conflicts

If stow fails with a conflict:
```bash
stow -d stow <pkg> -t "$HOME" --adopt -n  # dry run
```
The `--adopt` flag moves conflicting real files into the repo and symlinks them. If the conflict is a `.DS_Store`, `setup-common.sh` auto-cleans them before stowing.
