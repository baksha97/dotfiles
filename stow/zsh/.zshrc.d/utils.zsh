# Usage: gct <branch-name>
# e.g.   gct travis/CATCH-123/sample
# If <branch-name> exists on origin, creates a worktree tracking that remote branch.
# Otherwise, creates a new branch from origin/main, pushes it, and cd's into the worktree.
# Safe to run from any worktree or the main repo checkout.
gct() {
  [[ -n "$1" ]] || { echo "Usage: gct <branch-name>" >&2; return 1; }
  local branch="$1"

  local common_dir=$(git rev-parse --git-common-dir)
  [[ "$common_dir" = /* ]] || common_dir="$(git rev-parse --show-toplevel)/$common_dir"
  local repo_root=$(dirname "$common_dir")
  local repo_name=$(basename "$repo_root")

  local safe_branch="${branch//\//-}"
  local worktree_path="$(dirname "$repo_root")/${repo_name}-${safe_branch}"

  if git fetch origin "$branch" 2>/dev/null; then
    git worktree add --track -b "$branch" "$worktree_path" "origin/$branch" && \
    cd "$worktree_path"
  else
    git fetch origin main && \
    git worktree add --no-track -b "$branch" "$worktree_path" origin/main && \
    cd "$worktree_path" && \
    git push -u origin HEAD
  fi
}

# Usage: grmt [<worktree-path>]
# With no args, removes the worktree you're currently in.
# With a path arg, removes that worktree instead.
# Either way, cd's to the main repo root afterwards.
grmt() {
  local target="${1:-$(git rev-parse --show-toplevel)}"
  target="${target:A}"  # resolve to absolute/canonical path

  local common_dir=$(git -C "$target" rev-parse --git-common-dir)
  [[ "$common_dir" = /* ]] || common_dir="${target}/$common_dir"
  local repo_root=$(dirname "$common_dir")

  if [[ "${target:A}" = "${repo_root:A}" ]]; then
    echo "grmt: '$target' is the main repo checkout, not a worktree" >&2
    return 1
  fi

  cd "$repo_root" && git worktree remove "$target"
}
