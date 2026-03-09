# Project-local AI skill linker
#
# Broadcasts a project's skill definitions into the local directories where
# various AI coding tools look for them — all within the project, never global.
#
# Usage:
#   cd /path/to/project && link-skills          # auto-discover source
#   link-skills path/to/skills                  # explicit source
#   unlink-skills                               # remove symlinks
#
# _skills_candidates — relative paths probed (in priority order) to find the
#   project's canonical skills directory when no explicit path is given.
# _skills_targets — directories that link-skills will populate with symlinks.
#   The source's own convention is always skipped to avoid duplicates.

local -a _skills_candidates=(
  .ai-agent/skills
  .claude/skills
  .agents/skills
  .github/skills
  .copilot/skills
  .cursor/skills
)

local -a _skills_targets=(
  .claude/skills
  .agents/skills
  # .copilot/skills  # covered by .agents
  # .cursor/skills   # covered by .agents
)

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

  for candidate in "${_skills_candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      echo "${candidate:A}"
      return 0
    fi
  done

  echo "link-skills: no skills directory found. Tried: ${(j:, :)_skills_candidates}" >&2
  echo "  Run from the repo root, or pass an explicit path." >&2
  return 1
}

link-skills() {
  local skills_src
  skills_src=$(_find-skills-src "$1") || return 1
  echo "link-skills: using $skills_src"

  local project_root="${skills_src:h:h}"
  local src_ns="${${skills_src:h}:t}"

  for conv in "${_skills_targets[@]}"; do
    local target="$project_root/$conv"
    [[ "${${target:h}:t}" == "$src_ns" ]] && continue
    mkdir -p "$target"
    for skill in "$skills_src"/*/; do
      skill="${skill%/}"
      [[ -d "$skill" ]] || continue
      local name=$(basename "$skill")
      local link="$target/$name"
      [[ -L "$link" ]] && rm "$link"
      local rel_skill="${skill#$project_root/}"
      local -a depth=("${(@s:/:)${target#$project_root/}}")
      local dd="../"
      local up="${(j::)${(@)depth/*/$dd}}"
      ln -s "${up}${rel_skill}" "$link"
      echo "  Linked $link -> ${up}${rel_skill}"
    done
  done
}

link-agent-md() {
  if [[ ! -f CLAUDE.md && ! -f AGENT.md ]]; then
    echo "link-agent-md: no CLAUDE.md or AGENT.md found in current directory" >&2
    return 1
  fi

  # Already correct: AGENT.md is a real file, CLAUDE.md symlinks to it
  if [[ -f AGENT.md && ! -L AGENT.md && -L CLAUDE.md ]]; then
    echo "link-agent-md: already set up (CLAUDE.md -> AGENT.md)"
    return 0
  fi

  # Migrate: CLAUDE.md has the content, move it to AGENT.md
  if [[ -f CLAUDE.md && ! -L CLAUDE.md ]]; then
    if [[ -f AGENT.md && ! -L AGENT.md ]]; then
      echo "link-agent-md: both CLAUDE.md and AGENT.md are real files — resolve manually" >&2
      return 1
    fi
    rm -f AGENT.md
    mv CLAUDE.md AGENT.md
    echo "link-agent-md: moved CLAUDE.md -> AGENT.md"
  fi

  ln -sf AGENT.md CLAUDE.md
  echo "link-agent-md: CLAUDE.md -> AGENT.md"
}

unlink-skills() {
  local skills_src
  skills_src=$(_find-skills-src "$1") || return 1

  local project_root="${skills_src:h:h}"
  local src_ns="${${skills_src:h}:t}"

  for skill in "$skills_src"/*/; do
    skill="${skill%/}"
    [[ -d "$skill" ]] || continue
    local name=$(basename "$skill")
    for conv in "${_skills_targets[@]}"; do
      local target="$project_root/$conv"
      [[ "${${target:h}:t}" == "$src_ns" ]] && continue
      local link="$target/$name"
      local rel_skill="${skill#$project_root/}"
      local -a depth=("${(@s:/:)${target#$project_root/}}")
      local dd="../"
      local up="${(j::)${(@)depth/*/$dd}}"
      if [[ -L "$link" && "$(readlink "$link")" == "${up}${rel_skill}" ]]; then
        rm "$link"
        echo "  Unlinked $link"
      fi
    done
  done
}
