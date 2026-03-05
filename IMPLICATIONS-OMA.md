# Omakube Setup Implications (REVISED)

Analysis of running `./main.sh setup` on an Omakube-configured machine after automation improvements.

---

## High Severity — RESOLVED

### 1. `~/.gitconfig` Portability ✅
- **Issue:** Used to reference GCM (macOS-only) and lacked aliases.
- **Solution:** `stow/git/.gitconfig` now uses `helper = !gh auth git-credential` which is portable.
- **Result:** Git auth works out of the box on Linux/Omakube. Aliases (`co`, `br`, `ci`, `st`) and `pull.rebase = true` are now included in the dotfiles version.

### 2. VSCode Settings Merge ✅
- **Issue:** Existing settings were overwritten, losing Omakube customizations.
- **Solution:** `setup-common.sh` now uses a JSON merge framework (`merge-helpers.sh`) to preserve machine-specific keys (themes, AI configs, Copilot rules) from your existing `settings.json` before stowing.
- **Result:** Productivity settings are preserved; dotfiles settings are added/updated safely.

---

## Medium Severity — AUTO-HANDLED

### 3. Login Shell Change ✅
- **Issue:** Setup didn't change the shell from bash to zsh.
- **Solution:** Added an interactive prompt at the end of `setup-common.sh`: "Change login shell to zsh? [y/N]".
- **Result:** Users can now opt-in to the shell change during setup.

### 4. SDKMAN! / JVM Tool Conflicts ✅
- **Issue:** Unconditional SDKMAN! install could conflict with `mise`.
- **Solution:** Added smart detection. Setup now checks if `mise` is managing `java`, `gradle`, or `kotlin` and skips SDKMAN! installation if so.
- **Result:** No duplicate JVM tool managers.

### 5. Alacritty Modular Config ✅
- **Issue:** Entire config directory was replaced.
- **Solution:** Restructured `stow/alacritty/` to a modular format. `alacritty.toml` now imports `font.toml` and `theme.toml`.
- **Result:** Easier to customize fonts or themes per-machine without losing the core terminal configuration.

### 6. GUI App & Font Bloat ✅
- **Issue:** Automatic install of ~1GB Android Studio and heavy Nerd Fonts.
- **Solution:** Added explicit opt-in flags:
  - `--with-gui`: Installs VS Code, Chrome, Android Studio, etc. (Default: OFF)
  - `--with-fonts`: Installs all Nerd Font families. (Default: OFF)
- **Result:** Faster, lighter setup by default.

---

## New Capabilities

### 7. Dry-Run Mode ✅
- **Feature:** Added `--dry-run` flag to `main.sh`.
- **Benefit:** Preview exactly what `stow` will link, what packages will be installed, and what files will be backed up without making any changes.

### 8. Idempotent & Safe
- **Backups:** All real files are backed up to `backup/<timestamp>/` before being replaced by symlinks.
- **Checks:** Tool installers use `command -v` guards to skip already-installed software.

---

## Summary of Resolution

| Issue | Original Severity | Status |
|-------|-------------------|--------|
| Git Auth Breakage | High | **RESOLVED** (Portable config) |
| VSCode Data Loss | High | **RESOLVED** (JSON Merging) |
| Manual Shell Change | Medium | **AUTO-PROMPT** |
| JVM Tool Conflicts | Medium | **AUTO-DETECTED** |
| Unwanted GUI Bloat | Medium | **OPT-IN FLAGS** |
| Nerd Font Bandwidth | Low | **OPT-IN FLAGS** |

---

## Final Recommendation

Run the setup with the new safety flags:
```bash
./main.sh setup --dry-run
```
If the preview looks good, apply changes:
```bash
./main.sh setup --with-gui
```
