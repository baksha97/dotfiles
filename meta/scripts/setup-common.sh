#!/bin/bash
# setup-common.sh — platform-agnostic stow, git, and skills setup.
# Expects $profile and $DOTFILES_DIR to be set by the calling script.

set -e

: "${SETUP_STOW_ADOPT:=false}"
: "${SETUP_DRY_RUN:=false}"
: "${SETUP_SKIP_SDKMAN:=false}"
: "${SETUP_SKIP_STOW:=false}"

# Install SDKMAN! if not present
if [ "$SETUP_SKIP_SDKMAN" = true ]; then
  echo "Skipping SDKMAN install"
elif [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Clean up .DS_Store files that cause stow conflicts on macOS
if [ "$SETUP_DRY_RUN" = true ]; then
  echo "Dry run: would remove .DS_Store files from repo"
else
  find "$DOTFILES_DIR" -name .DS_Store -delete
fi

backup_dir="$DOTFILES_DIR/backup/$(date +%Y-%m-%d_%H-%M-%S)"
backed_up=false

# ── Stow helpers ─────────────────────────────────────────────────────────────

# stow_backup TARGET
# If TARGET is a real file/dir, back it up with its path preserved and remove it.
# If TARGET is a symlink, remove it without backup. Explicit stow_backup calls
# are for targets we do not want stow --adopt to pull into the repo.
stow_backup() {
  local target="$1"
  local rel backup_target

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [ "$backed_up" = false ]; then
      [ "$SETUP_DRY_RUN" = true ] || mkdir -p "$backup_dir"
      backed_up=true
    fi

    if [[ "$target" == "$HOME/"* ]]; then
      rel="${target#$HOME/}"
    else
      rel="${target#/}"
    fi
    backup_target="$backup_dir/$rel"

    if [ "$SETUP_DRY_RUN" = true ]; then
      echo "Dry run: would back up $target to $backup_target"
    else
      mkdir -p "$(dirname "$backup_target")"
      cp -R "$target" "$backup_target"
    fi
  fi

  if [ -L "$target" ]; then
    if [ "$SETUP_DRY_RUN" = true ]; then
      echo "Dry run: would remove symlink $target"
    else
      rm "$target"
    fi
  elif [ -e "$target" ]; then
    if [ "$SETUP_DRY_RUN" = true ]; then
      echo "Dry run: would remove $target"
    else
      rm -rf "$target"
    fi
  fi

  return 0
}

setup_mkdir_p() {
  local dir="$1"
  if [ "$SETUP_DRY_RUN" = true ]; then
    echo "Dry run: would create directory $dir"
  else
    mkdir -p "$dir"
  fi
}

# stow_package PKG [FLAGS...]
# Run stow for PKG against STOW_TARGET (defaults to $HOME).
# Callers set STOW_TARGET before calling when a non-$HOME target is needed.
stow_package() {
  local pkg="$1"; shift
  local target="${STOW_TARGET:-$HOME}"
  local mode="--restow"
  local flags=()

  [ "$SETUP_STOW_ADOPT" = true ] && mode="--adopt"
  [ "$SETUP_DRY_RUN" = true ] && flags+=(--simulate)

  if [ "$SETUP_DRY_RUN" = true ] && [ ! -d "$target" ]; then
    echo "Dry run: target $target does not exist; would stow $pkg there"
    return 0
  fi

  if [ "$SETUP_DRY_RUN" = true ]; then
    echo "Dry run: would stow $pkg to $target using $mode"
  fi

  stow -d "$DOTFILES_DIR/stow" -t "$target" "$mode" "${flags[@]}" "$@" "$pkg"
}

# ── Stow packages ─────────────────────────────────────────────────────────────
# Each file in stow.d/ installs one stow package. Adding a new package = add one file.
STOW_D="$DOTFILES_DIR/meta/scripts/stow.d"
if [ "$SETUP_SKIP_STOW" = true ]; then
  echo "Skipping stow packages"
else
  for f in "$STOW_D/"*.sh; do
    unset STOW_TARGET
    [ -f "$f" ] && source "$f"
  done
fi

if [ "$backed_up" = true ]; then
  if [ "$SETUP_DRY_RUN" = true ]; then
    echo "Dry run: would back up existing configs under $backup_dir/"
  else
    echo "  Backed up existing configs to $backup_dir/"
  fi
fi

# ── GitHub CLI credential helper ──────────────────────────────────────────────
# We manually manage the gh helper in stow/git/.gitconfig using !gh
# to avoid absolute path pollution from 'gh auth setup-git'.
if ! command -v gh &>/dev/null; then
  echo "  Warning: GitHub CLI (gh) not found — credential helper might fail."
fi

# ── Agent Skills ──────────────────────────────────────────────────────────────
# Symlink the skills directory for Copilot CLI, Cursor IDE, and others.
skills_src="$(cd "$DOTFILES_DIR/meta/skills" && pwd)"
for target in "$HOME/.copilot/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills" "$HOME/.claude/skills"; do
  if [ "$SETUP_DRY_RUN" = true ]; then
    echo "Dry run: would link $target -> $skills_src"
    continue
  fi
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    rm -rf "$target"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$skills_src" "$target"
  echo "  Linked $target -> $skills_src"
done

echo "Dotfiles installation complete! Open a new shell to pick up changes."
