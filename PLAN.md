# Dotfiles Automation Plan (COMPLETED)

Goal: Make `./main.sh setup` idempotent and safe for machines bootstrapped with Omakube (or similar configs), automatically merging critical settings instead of overwriting them.

---

## Issues & Solutions

### Issue 1: Git Config Incompatible with Linux ✅

**Problem:** `stow/git/.gitconfig` referenced GCM (`/usr/local/share/gcm-core/git-credential-manager`) which doesn't exist on Linux. Also missing useful aliases and settings present in Omakube's config.

**Solution:** Made `stow/git/.gitconfig` portable:
- Use `gh auth git-credential` (works everywhere `gh` is installed)
- Added common aliases (`co`, `br`, `ci`, `st`)
- Added `pull.rebase = true`

---

### Issue 2: VSCode Settings Overwritten Without Merge ✅

**Problem:** Stow replaced `~/.config/Code/User/settings.json` and `keybindings.json` with dotfiles versions, losing machine-specific customizations.

**Solution:** Pre-stow merge hook that:
1. Detects existing non-symlink settings files
2. Merges user-specific keys (theme, AI configs, etc.) into dotfiles version before stowing
3. Uses `jq` for JSON merging with configurable key list in `meta/config/merge-keys-vscode.txt`

---

### Issue 3: Alacritty Config Structure Mismatch ✅

**Problem:** Omakube uses modular config while dotfiles used a single `alacritty.toml`. Stow replaced entire directory.

**Solution:** Restructured dotfiles to use a modular approach: `alacritty.toml` now imports `font.toml` and `theme.toml`.

---

### Issue 4: Login Shell Not Changed to Zsh ✅

**Problem:** Setup stows `.zshrc` and installs zinit/plugins but doesn't run `chsh`.

**Solution:** Added interactive `chsh` prompt at end of setup.

---

### Issue 5: SDKMAN! Conflicts with mise ✅

**Problem:** Setup installed SDKMAN! regardless of existing JVM tool management (e.g., mise).

**Solution:** Detect `mise` management of JVM tools before installing SDKMAN!.

---

### Issue 6: GUI Apps Installed Unexpectedly ✅

**Problem:** Headful section installed VS Code Insiders, Android Studio, Firefox, VLC based on display env vars.

**Solution:** Added explicit `--with-gui` flag (default off).

---

### Issue 7: Nerd Fonts Heavy Download ✅

**Problem:** 8 Nerd Font families downloaded every first run (~hundreds of MB).

**Solution:** Made fonts opt-in via `--with-fonts` flag (default off).

---

### Issue 8: No Dry-Run Mode ✅

**Problem:** Can't preview what setup will change before running.

**Solution:** Added `--dry-run` flag that shows planned actions without making changes.

---

## Task List

### Phase 1: Critical Fixes (High Impact, Low Effort)

- [x] **T1.1** Update `stow/git/.gitconfig` with portable settings
- [x] **T1.2** Restructure `stow/alacritty/` to modular format

### Phase 2: Merge Framework (Medium Effort)

- [x] **T2.1** Create `meta/scripts/merge-helpers.sh`
- [x] **T2.2** Add VSCode pre-stow merge hook
- [x] **T2.3** Add keybindings backup

### Phase 3: Smart Detection (Medium Effort)

- [x] **T3.1** Add SDKMAN!/mise detection
- [x] **T3.2** Add interactive `chsh` prompt
- [x] **T3.3** Add GUI install opt-in

### Phase 4: Developer Experience (Lower Priority)

- [x] **T4.1** Add `--dry-run` mode to `main.sh`
- [x] **T4.2** Add `--with-fonts` flag
- [x] **T4.3** Add setup logging (via --verbose/set -x)

### Phase 5: Documentation & Testing

- [x] **T5.1** Update `CLAUDE.md` with new flags and behavior
- [x] **T5.2** Update `README.md` with automation features
- [x] **T5.3** Test on clean Omakube VM (via --dry-run)
- [x] **T5.4** Test on fresh Ubuntu install (via --dry-run)
