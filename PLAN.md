# Dotfiles Automation Plan

Goal: Make `./main.sh setup` idempotent and safe for machines bootstrapped with Omakube (or similar configs), automatically merging critical settings instead of overwriting them.

---

## Issues & Solutions

### Issue 1: Git Config Incompatible with Linux

**Problem:** `stow/git/.gitconfig` references GCM (`/usr/local/share/gcm-core/git-credential-manager`) which doesn't exist on Linux. Also missing useful aliases and settings present in Omakube's config.

**Impact:** Git auth breaks; aliases lost.

**Solution:** Make `stow/git/.gitconfig` portable across platforms:
- Use `gh auth git-credential` (works everywhere `gh` is installed)
- Add common aliases (`co`, `br`, `ci`, `st`)
- Add `pull.rebase = true`
- Use conditional includes for platform-specific settings if needed

**Automation:** Fix at source — no runtime merge needed.

---

### Issue 2: VSCode Settings Overwritten Without Merge

**Problem:** Stow replaces `~/.config/Code/User/settings.json` and `keybindings.json` with dotfiles versions, losing machine-specific customizations (Omakube themes, AI tool settings, etc.).

**Impact:** Loss of productivity settings; manual restore from backup required.

**Solution:** Pre-stow merge hook that:
1. Detects existing non-symlink settings files
2. Extracts user-specific keys to preserve (theme, AI configs, etc.)
3. Merges into dotfiles version before stowing
4. Uses `jq` for JSON merging with configurable key list

**Automation:** Add `meta/scripts/merge-helpers.sh` with `merge_json_preserve_keys()` function, called in `setup-common.sh` before VSCode stow.

---

### Issue 3: Alacritty Config Structure Mismatch

**Problem:** Omakube uses modular config (`font.toml`, `theme.toml`, `pane.toml`, etc.) while dotfiles uses single `alacritty.toml`. Stow replaces entire directory.

**Impact:** Loss of modular organization; manual reconfiguration needed.

**Solution:** Two options:
- **Option A (Recommended):** Restructure dotfiles to use modular approach — matches Omakube, easier to maintain
- **Option B:** Add merge hook that converts modular to single file

**Automation:** Restructure `stow/alacritty/` to modular format; stow will naturally adopt existing modular files.

---

### Issue 4: Login Shell Not Changed to Zsh

**Problem:** Setup stows `.zshrc` and installs zinit/plugins but doesn't run `chsh`. User must manually change shell.

**Impact:** Zsh only works in nested shells; login shell remains bash.

**Solution:** Add optional `chsh` step at end of setup:
- Prompt user: "Change login shell to zsh? [y/N]"
- Run `chsh -s $(which zsh)` if confirmed
- Skip if non-interactive (CI/SSH)

**Automation:** Add to `setup-common.sh` with interactive prompt guard.

---

### Issue 5: SDKMAN! Conflicts with mise

**Problem:** Setup installs SDKMAN! + gradle/kotlin regardless of existing JVM tool management (e.g., mise).

**Impact:** Duplicate tool installations; potential PATH conflicts.

**Solution:** Detect existing JVM management before installing SDKMAN!:
- Check if `mise` is installed and has Java/gradle/kotlin
- Skip SDKMAN! installation if mise manages these tools
- Or make SDKMAN! installation opt-in via flag

**Automation:** Add detection in `setup-linux.sh` before SDKMAN! block.

---

### Issue 6: GUI Apps Installed Unexpectedly

**Problem:** Headful section installs VS Code Insiders, Android Studio, Firefox, VLC based on display env vars — which may be set in desktop terminals.

**Impact:** Unwanted ~1GB downloads (especially Android Studio).

**Solution:** Add explicit opt-in flag or prompt:
- `--with-gui` flag to enable GUI installs
- Or prompt: "Install GUI applications? [y/N]"
- Default to skip in non-interactive mode

**Automation:** Add flag/prompt to `setup-linux.sh` headful section.

---

### Issue 7: Nerd Fonts Heavy Download

**Problem:** 8 Nerd Font families downloaded every first run (~hundreds of MB).

**Impact:** Slow setup on bandwidth-limited connections.

**Solution:** Make fonts optional or lazy:
- `--with-fonts` flag (default off)
- Or check if fonts already exist and skip
- Or install only most common font (JetBrainsMono)

**Automation:** Add flag to `setup-linux.sh`; current marker-file approach already prevents re-download.

---

### Issue 8: No Dry-Run Mode

**Problem:** Can't preview what setup will change before running.

**Impact:** Fear of running setup; manual inspection required.

**Solution:** Add `--dry-run` flag that:
- Shows what would be stowed
- Shows what would be installed
- Shows what would be backed up
- Exits without making changes

**Automation:** Add to `main.sh` with verbose output mode.

---

## Task List

### Phase 1: Critical Fixes (High Impact, Low Effort)

- [ ] **T1.1** Update `stow/git/.gitconfig` with portable settings
  - Replace GCM with `gh auth git-credential`
  - Add aliases: `co`, `br`, `ci`, `st`
  - Add `pull.rebase = true`
  - Test on Linux machine

- [ ] **T1.2** Restructure `stow/alacritty/` to modular format
  - Create `stow/alacritty/.config/alacritty/` structure
  - Split into: `alacritty.toml`, `font.toml`, `theme.toml`
  - Import sub-files from main `alacritty.toml`
  - Move themes to `themes/` subdirectory

### Phase 2: Merge Framework (Medium Effort)

- [ ] **T2.1** Create `meta/scripts/merge-helpers.sh`
  - `merge_json_preserve_keys()`: Merge specific keys from existing JSON into new
  - `backup_if_exists()`: Timestamped backup before overwrite
  - `is_symlink()`: Check if path is symlink

- [ ] **T2.2** Add VSCode pre-stow merge hook
  - In `setup-common.sh`, before VSCode stow
  - Merge keys: theme, AI tool settings, custom paths
  - Configurable key list in `meta/config/merge-keys-vscode.txt`

- [ ] **T2.3** Add keybindings merge
  - Similar to settings merge
  - Preserve machine-specific shortcuts

### Phase 3: Smart Detection (Medium Effort)

- [ ] **T3.1** Add SDKMAN!/mise detection
  - In `setup-linux.sh`, check for mise before SDKMAN! install
  - Skip if mise already manages Java toolchain
  - Log decision to user

- [ ] **T3.2** Add interactive `chsh` prompt
  - At end of `setup-common.sh`
  - Skip if non-interactive (`$PS1` empty or CI env)
  - Show: "Change login shell to zsh? [y/N]"

- [ ] **T3.3** Add GUI install opt-in
  - Replace auto-detection with `--with-gui` flag
  - Or add interactive prompt
  - Default to skip

### Phase 4: Developer Experience (Lower Priority)

- [ ] **T4.1** Add `--dry-run` mode to `main.sh`
  - Show planned actions without executing
  - List: stow packages, installs, backups
  - Verbose output with `--verbose` flag

- [ ] **T4.2** Add `--with-fonts` flag
  - Make Nerd Fonts opt-in
  - Default to skip (or install only JetBrainsMono)

- [ ] **T4.3** Add setup logging
  - Log to `~/.local/share/dotfiles/setup.log`
  - Timestamps for each action
  - Useful for debugging

### Phase 5: Documentation & Testing

- [ ] **T5.1** Update `CLAUDE.md` with new flags and behavior

- [ ] **T5.2** Update `README.md` with automation features

- [ ] **T5.3** Test on clean Omakube VM
  - Verify all merges work correctly
  - Verify no data loss
  - Verify idempotency (run twice, no changes second time)

- [ ] **T5.4** Test on fresh Ubuntu install
  - Verify setup completes without errors
  - Verify all tools installed correctly

---

## Execution Order

```
Week 1: Phase 1 (T1.1, T1.2)
Week 2: Phase 2 (T2.1, T2.2, T2.3)  
Week 3: Phase 3 (T3.1, T3.2, T3.3)
Week 4: Phase 4 & 5 (T4.1-T4.3, T5.1-T5.4)
```

---

## Configuration Files to Create

| File | Purpose |
|------|---------|
| `meta/scripts/merge-helpers.sh` | Reusable merge functions |
| `meta/config/merge-keys-vscode.txt` | VSCode keys to preserve (one per line) |
| `meta/config/merge-keys-keybindings.txt` | Keybinding IDs to preserve |

---

## Success Criteria

- [ ] Running `./main.sh setup` on Omakube machine preserves all user settings
- [ ] Git auth works immediately after setup (no manual fix needed)
- [ ] VSCode loads with merged settings (theme + AI configs preserved)
- [ ] Alacritty config preserved if using modular structure
- [ ] Setup is idempotent (can run multiple times safely)
- [ ] Dry-run mode shows exactly what will change
- [ ] Setup completes in <5 minutes on standard broadband
