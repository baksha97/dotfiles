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

  # Derive the source namespace (e.g. ".agents" from "/proj/.agents/skills") so we
  # can skip the matching global dir — tools already scan the project dir directly,
  # so linking there too would cause duplicate skill conflicts.
  local src_ns="${${skills_src:h}:t}"

  local -a bases=("$HOME/.copilot/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills")

  for base in "${bases[@]}"; do
    [[ "${${base:h}:t}" == "$src_ns" ]] && continue
    mkdir -p "$base"
    for skill in "$skills_src"/*/; do
      skill="${skill%/}"
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

  local src_ns="${${skills_src:h}:t}"
  local -a bases=("$HOME/.copilot/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills")

  for skill in "$skills_src"/*/; do
    skill="${skill%/}"   # strip trailing slash added by glob
    [[ -d "$skill" ]] || continue
    local name=$(basename "$skill")
    for base in "${bases[@]}"; do
      [[ "${${base:h}:t}" == "$src_ns" ]] && continue
      local link="$base/$name"
      if [[ -L "$link" && "$(readlink "$link")" == "$skill" ]]; then
        rm "$link"
        echo "  Unlinked $link"
      fi
    done
  done
}
