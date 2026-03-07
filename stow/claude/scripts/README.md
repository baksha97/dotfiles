# Scripts

Utility shell scripts for maintaining your Claude Code setup.

## update-cc-plugins.sh

Bulk-updates all installed Claude Code marketplaces and plugins/skills in one shot.

**Usage:**

```sh
bash ~/.claude/scripts/update-cc-plugins.sh
```

**What it does:**

1. Runs `claude plugin marketplace update` to refresh all configured marketplaces.
2. Reads `~/.claude/plugins/installed_plugins.json` and calls `claude plugin update <plugin>` for each entry.
3. Prints a summary: how many plugins were updated, skipped (no longer in the marketplace), or failed.
