#!/usr/bin/env bash
set -euo pipefail

# Update all Claude Code marketplaces and plugins/skills

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}==>${NC} $*"; }
section() { echo -e "\n${YELLOW}>>> $*${NC}"; }

PLUGINS_JSON="${HOME}/.claude/plugins/installed_plugins.json"

# 1. Update all marketplaces
section "Updating marketplaces"
claude plugin marketplace update
info "All marketplaces updated"

# 2. Update all installed plugins
section "Updating plugins"
python3 - <<'EOF'
import json, subprocess, sys
from pathlib import Path

plugins_file = Path.home() / ".claude/plugins/installed_plugins.json"
data = json.loads(plugins_file.read_text())

ok, not_found, failed = [], [], []
for plugin_key in data["plugins"]:
    print(f"  Updating {plugin_key}...", end=" ", flush=True)
    result = subprocess.run(
        ["claude", "plugin", "update", plugin_key],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print("ok")
        ok.append(plugin_key)
    else:
        msg = (result.stderr or result.stdout).strip()
        if "not found" in msg.lower():
            print("skipped (not found in marketplace)")
            not_found.append((plugin_key, msg))
        else:
            print(f"FAILED ({msg})")
            failed.append((plugin_key, msg))

print(f"\nResults: {len(ok)} updated, {len(not_found)} skipped, {len(failed)} failed")
if not_found:
    print("Skipped (no longer in marketplace — consider uninstalling):")
    for name, _ in not_found:
        print(f"  - {name}")
if failed:
    print("Failed:")
    for name, msg in failed:
        print(f"  - {name}: {msg}")
    sys.exit(1)
EOF

section "Done — restart Claude Code to apply updates"
