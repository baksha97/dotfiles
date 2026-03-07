# Usage: gct <branch-name>
# e.g.   gct travis/CATCH-123/sample
# If <branch-name> exists on origin, creates a worktree tracking that remote branch.
# Otherwise, creates a new branch from origin/main, pushes it, and cd's into the worktree.
# Safe to run from any worktree or the main repo checkout.
gct() {
  [[ -n "$1" ]] || { echo "Usage: gct <branch-name>" >&2; return 1; }
  local branch="$1"

  local toplevel=$(git rev-parse --show-toplevel)
  local repo_name=$(basename -s .git "$(git remote get-url origin)")

  local safe_branch="${branch//\//-}"
  local worktree_path="$(dirname "$toplevel")/${repo_name}-${safe_branch}"

  if git fetch origin "$branch" 2>/dev/null; then
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$worktree_path" "$branch" && \
      cd "$worktree_path"
    else
      git worktree add --track -b "$branch" "$worktree_path" "origin/$branch" && \
      cd "$worktree_path"
    fi
  else
    git fetch origin main && \
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$worktree_path" "$branch" && \
      cd "$worktree_path" && \
      git push -u origin HEAD
    else
      git worktree add --no-track -b "$branch" "$worktree_path" origin/main && \
      cd "$worktree_path" && \
      git push -u origin HEAD
    fi
  fi
}

# _find-skills-src [explicit-path]
# Resolves the skills source directory. If an explicit path is given, validates and
# returns it. Otherwise probes well-known project conventions in priority order.
# Prints the resolved absolute path and returns 0, or prints an error and returns 1.
_find-skills-src() {
  if [[ -n "$1" ]]; then
    local resolved="${1:A}"
    if [[ ! -d "$resolved" ]]; then
      echo "_find-skills-src: '$1' is not a directory" >&2
      return 1
    fi
    echo "$resolved"
    return 0
  fi

  # Probe common project conventions in priority order.
  local -a candidates=(
    .ai-agent/skills   # dotfiles / this repo convention
    .claude/skills     # Claude Code
    .agents/skills     # generic agents
    .github/skills     # GitHub ecosystem
    .copilot/skills    # GitHub Copilot
  )

  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      echo "${candidate:A}"
      return 0
    fi
  done

  echo "link-skills: no skills directory found. Tried: ${(j:, :)candidates}" >&2
  echo "  Run from the repo root, or pass an explicit path." >&2
  return 1
}

# Usage: link-skills [dir]
# Links each skill subdirectory in the project's skills directory into the standard
# agent skill locations: ~/.copilot/skills, ~/.cursor/skills, ~/.agents/skills.
# Auto-discovers the source from common conventions (.ai-agent/skills, .claude/skills,
# .agents/skills, .github/skills, .copilot/skills) when no explicit path is given.
# If a target is currently a whole-dir symlink (from dotfiles setup), it is expanded
# into individual symlinks first so global skills are preserved. Idempotent.
link-skills() {
  local skills_src
  skills_src=$(_find-skills-src "$1") || return 1
  echo "link-skills: using $skills_src"

  local -a bases=("$HOME/.copilot/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills")

  for base in "${bases[@]}"; do
    # If the target is a whole-dir symlink (e.g. from dotfiles setup), expand it
    # into individual skill symlinks so project skills can coexist with global ones.
    if [[ -L "$base" ]]; then
      local global_src=$(readlink "$base")
      rm "$base"
      mkdir -p "$base"
      for global_skill in "$global_src"/*/; do
        [[ -d "$global_skill" ]] || continue
        ln -s "$global_skill" "$base/$(basename "$global_skill")"
      done
    else
      mkdir -p "$base"
    fi

    for skill in "$skills_src"/*/; do
      [[ -d "$skill" ]] || continue
      local name=$(basename "$skill")
      local link="$base/$name"
      [[ -L "$link" ]] && rm "$link"
      ln -s "$skill" "$link"
      echo "  Linked $link -> $skill"
    done
  done
}

# Usage: unlink-skills [dir]
# Removes symlinks created by link-skills. Auto-discovers the source directory using
# the same convention probing as link-skills when no explicit path is given.
unlink-skills() {
  local skills_src
  skills_src=$(_find-skills-src "$1") || return 1

  local -a bases=("$HOME/.copilot/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills")

  for skill in "$skills_src"/*/; do
    [[ -d "$skill" ]] || continue
    local name=$(basename "$skill")
    for base in "${bases[@]}"; do
      local link="$base/$name"
      if [[ -L "$link" && "$(readlink "$link")" == "$skill" ]]; then
        rm "$link"
        echo "  Unlinked $link"
      fi
    done
  done
}

# Usage: grmt [--force|-f] [<worktree-path>]
# With no args, removes the worktree you're currently in.
# With a path arg, removes that worktree instead.
# Either way, cd's to the main repo root afterwards.
grmt() {
  local force_flag=""
  if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    force_flag="--force"
    shift
  fi

  local target="${1:-$(git rev-parse --show-toplevel)}"
  target="${target:A}"  # resolve to absolute/canonical path

  local main_worktree=$(git -C "$target" worktree list --porcelain | head -1 | sed 's/^worktree //')

  if [[ "${target}" = "${main_worktree}" ]]; then
    echo "grmt: '$target' is the main repo checkout, not a worktree" >&2
    return 1
  fi

  if [[ -n "$force_flag" ]]; then
    cd "$main_worktree" && git worktree remove --force "$target"
  else
    cd "$main_worktree" && git worktree remove "$target"
  fi
}
