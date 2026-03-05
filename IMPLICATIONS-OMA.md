# Omakube Setup Implications

Analysis of running `./main.sh setup` on this machine (Omakube-configured Ubuntu desktop).

---

## High Severity — Likely to Break Things

### 1. `~/.gitconfig` Will Be Overwritten — Git Auth Will Break

**Current state:** `~/.gitconfig` is a real file (not a symlink) configured with:
- `gh auth git-credential` as the credential helper (functional on this machine)
- Local aliases (`co`, `br`, `ci`, `st`)
- `pull.rebase = true`

**After setup:** `stow/git/.gitconfig` will be symlinked instead. That file references:
```
helper = /usr/local/share/gcm-core/git-credential-manager
```
**GCM is not installed on this machine** (`/usr/local/share/gcm-core/` does not exist).
Result: all git operations requiring authentication (`push`, `pull`, `fetch` on private repos) will fail with a "credential helper not found" error.

Additionally, these settings from your current `~/.gitconfig` will be **lost**:
- Aliases: `co`, `br`, `ci`, `st`
- `pull.rebase = true`

**Fix before running:** Update `stow/git/.gitconfig` to:
1. Use `helper = !/usr/bin/gh auth git-credential` instead of GCM
2. Add the missing aliases and `pull.rebase = true`

---

### 2. VSCode `settings.json` and `keybindings.json` Will Be Replaced

**Current state:** `~/.config/Code/User/settings.json` (1.4k) contains heavily customized Omakube settings including `chat.tools.terminal.autoApprove` rules, Tokyo Night theme, custom git/editor settings, and more. `keybindings.json` also has machine-specific bindings. Both are real files.

**After setup:** `setup-common.sh` backs them up and then stows the dotfiles versions — which are simpler and will not contain your Omakube customizations.

The backup is saved to `backup/<timestamp>/` so recovery is possible, but you will lose the active config.

**Fix before running:** Merge your current settings into `stow/vscode/settings.json` and `stow/vscode/keybindings.json`, or manually restore from backup afterward.

---

## Medium Severity — Behavior Changes / Gaps

### 3. Default Shell Remains `bash` After Setup

`$SHELL` is `/bin/bash`. The setup stows `.zshrc`, `.zshrc.d/`, `.p10k.zsh`, and installs zinit plugins — but **does not run `chsh`**. Nothing in `main.sh` or `setup-common.sh` changes the login shell.

After setup you need to manually run:
```sh
chsh -s $(which zsh)
```
Then log out and back in for it to take effect.

### 4. SDKMAN! Will Be Installed + Gradle/Kotlin Downloaded

`setup-common.sh` installs SDKMAN! if `~/.sdkman` is absent (it is absent here). Then `setup-linux.sh` installs gradle and kotlinc via `sdk install`. This is a large addition (~hundreds of MB) and may conflict with existing JVM tool management (e.g. via `mise`).

### 5. `alacritty.toml` Replaces Existing Alacritty Config

`~/.config/alacritty/` exists as a real directory. `setup-common.sh` correctly backs it up and removes it before stowing, but your current Alacritty configuration will be replaced by the dotfiles version.

### 6. GUI App Installs Depend on Environment Variables

The headful section (`setup-linux.sh` lines 179-248) only runs if `$DISPLAY`, `$WAYLAND_DISPLAY`, or `$XDG_CURRENT_DESKTOP` is set. These are **unset in headless sessions** (e.g. SSH, Claude Code's terminal).

If run from a desktop terminal emulator where the display env is inherited, it will attempt to install:
- VS Code Insiders (`code-insiders`) — likely not installed, will be added
- Android Studio to `/opt/android-studio` — not installed, ~1 GB download
- Firefox, VLC — may or may not already be present

VS Code (`code`) and Google Chrome are already present on this machine and will be skipped correctly.

---

## Low Severity — Additions, Idempotent, or Harmless

### 7. Tools Already Installed — Correctly Skipped

These are already installed and their install blocks will be skipped via `command -v` guards:

| Tool | Location |
|------|----------|
| `docker` | `/usr/bin/docker` |
| `gh` | `/usr/bin/gh` |
| `lazygit` | `/usr/local/bin/lazygit` |
| `zoxide` | `/usr/bin/zoxide` |
| `stow` | `/usr/bin/stow` |
| `node` / `npm` | via mise |
| `just` | via mise |
| `opencode` | `~/.opencode/bin/opencode` (may not be on PATH during setup, but installer is idempotent) |

### 8. New Tools Will Be Installed

These are missing and will be freshly installed:

| Tool | Method |
|------|--------|
| `yq` | Binary from GitHub releases to `/usr/local/bin/yq` |
| `typos` | Binary from GitHub releases to `/usr/local/bin/typos` |
| `tailscale` | Official install script |
| `vercel` | `npm install -g vercel` |

All are safe additions with no expected conflicts.

### 9. Nerd Fonts — Bandwidth-Heavy but Harmless

8 Nerd Font families will be downloaded and installed to `~/.local/share/fonts/`. Marker files prevent re-download on subsequent runs.

### 10. `scrcpy` in `linux.packages`

`scrcpy` is listed in `meta/packages/linux.packages` but **is already installed** on this machine (via apt). It will be skipped or potentially upgraded — no new addition, but the package remains in the list for other machines.

### 11. `path.zsh` Has macOS-Only Paths

`stow/zsh/.zshrc.d/path.zsh` includes paths for Homebrew Anaconda and `~/Library/Android/sdk`. Both are guarded by `[[ -d ... ]]` and safely no-op on Linux. Dead code but no breakage.

---

## Summary

| Issue | Severity | Auto-handled? |
|-------|----------|---------------|
| GCM credential helper missing — git auth breaks | High | No — fix `.gitconfig` first |
| Git aliases & pull.rebase lost | High | No — add to `.gitconfig` first |
| VSCode settings replaced | High | Backed up, but not merged |
| Shell stays bash (no `chsh`) | Medium | Manual `chsh` needed after |
| SDKMAN! + gradle/kotlin installed | Medium | Automatic, possibly unwanted |
| Alacritty config replaced | Medium | Backed up automatically |
| GUI installs depend on display env vars | Medium | Situational |
| New tools added (yq, typos, tailscale, vercel) | Low | Safe additions |
| Nerd Font downloads | Low | Idempotent with markers |

---

## Recommended Steps Before Running

1. **Fix the credential helper in `stow/git/.gitconfig`** — replace the GCM path with `helper = !/usr/bin/gh auth git-credential`
2. **Add missing git settings to `stow/git/.gitconfig`** — aliases (`co`, `br`, `ci`, `st`) and `pull.rebase = true`
3. **Merge your VSCode settings** into `stow/vscode/settings.json` so you don't lose Omakube customizations
4. **Run `./main.sh setup`** from a headless terminal to avoid triggering unwanted GUI installs (Android Studio in particular)
5. **After setup:** run `chsh -s $(which zsh)` and log out/in to activate zsh as your login shell
