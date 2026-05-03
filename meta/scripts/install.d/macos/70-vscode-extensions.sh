#!/bin/bash
# vscode extensions — install profile-specific VS Code extensions best-effort.
command -v code &>/dev/null || { echo "  Skipped VS Code extensions (code not found)"; return 0; }

extensions_file="$DOTFILES_DIR/meta/homebrew/vscode.$profile"
[ -f "$extensions_file" ] || return 0

installed_extensions="$(mktemp)"
if ! code --list-extensions > "$installed_extensions" 2>/dev/null; then
  echo "  Warning: could not list VS Code extensions; skipping."
  rm -f "$installed_extensions"
  return 0
fi

failures=0
while IFS= read -r extension || [ -n "$extension" ]; do
  [[ -z "$extension" || "$extension" == \#* ]] && continue
  grep -Fixq "$extension" "$installed_extensions" && continue
  code --locate-extension "$extension" &>/dev/null && continue

  echo "Installing VS Code extension $extension..."
  if code --install-extension "$extension"; then
    echo "$extension" >> "$installed_extensions"
  else
    echo "  Warning: failed to install VS Code extension $extension"
    failures=$((failures + 1))
  fi
done < "$extensions_file"

rm -f "$installed_extensions"

if [ "$failures" -gt 0 ]; then
  echo "  Warning: $failures VS Code extension install(s) failed; continuing."
fi

return 0
