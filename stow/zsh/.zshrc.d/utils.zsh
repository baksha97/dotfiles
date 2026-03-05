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

# Usage: grmt [<worktree-path>]
# With no args, removes the worktree you're currently in.
# With a path arg, removes that worktree instead.
# Either way, cd's to the main repo root afterwards.
grmt() {
  local target="${1:-$(git rev-parse --show-toplevel)}"
  target="${target:A}"  # resolve to absolute/canonical path

  local main_worktree=$(git -C "$target" worktree list --porcelain | head -1 | sed 's/^worktree //')

  if [[ "${target}" = "${main_worktree}" ]]; then
    echo "grmt: '$target' is the main repo checkout, not a worktree" >&2
    return 1
  fi

  cd "$main_worktree" && git worktree remove "$target"
}
