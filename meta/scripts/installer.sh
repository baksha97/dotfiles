# installer.sh — non-symlink based "merge" installation.
# Expects $DOTFILES_DIR to be set by the calling script (main.sh).

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[install]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[success]${NC} $1"; }

install_skills() {
    local sub_target="$1"
    local skills_src="$DOTFILES_DIR/meta/.ai-agent/skills"
    
    if [ ! -d "$skills_src" ]; then
        error "Skills source directory not found: $skills_src"
    fi

    local targets=(
        "$HOME/.copilot/skills"
        "$HOME/.cursor/skills"
        "$HOME/.agents/skills"
    )

    if [ -n "$sub_target" ]; then
        # Check if it's a direct match or a fuzzy match
        local matched_dir=""
        if [ -d "$skills_src/$sub_target" ]; then
            matched_dir="$sub_target"
        else
            # Try fuzzy matching (e.g. "android-emu" -> "android-emulator-skill")
            matched_dir=$(ls "$skills_src" | grep "$sub_target" | head -n 1 || true)
        fi

        if [ -z "$matched_dir" ] || [ ! -d "$skills_src/$matched_dir" ]; then
            error "Skill not found: $sub_target"
        fi
        
        log "Installing specific skill: $matched_dir"
        for target in "${targets[@]}"; do
            log "  Merging into $target/$matched_dir"
            mkdir -p "$target/$matched_dir"
            cp -rf "$skills_src/$matched_dir"/* "$target/$matched_dir/"
        done
    else
        log "Installing all agent skills..."
        for target in "${targets[@]}"; do
            log "  Merging into $target"
            mkdir -p "$target"
            cp -rf "$skills_src"/* "$target/"
        done
    fi
    success "Agent skills installation complete."
}

install_zsh() {
    local sub_target="$1"
    local zsh_src="$DOTFILES_DIR/stow/zsh/.zshrc.d"
    local zsh_target="$HOME/.zshrc.d"

    if [ ! -d "$zsh_src" ]; then
        error "Zsh source directory not found: $zsh_src"
    fi

    mkdir -p "$zsh_target"

    if [ -n "$sub_target" ]; then
        # Ensure it ends in .zsh
        [[ "$sub_target" == *.zsh ]] || sub_target="${sub_target}.zsh"
        
        if [ ! -f "$zsh_src/$sub_target" ]; then
            error "Zsh utility not found: $sub_target"
        fi
        
        log "Installing specific zsh utility: $sub_target"
        cp -f "$zsh_src/$sub_target" "$zsh_target/"
    else
        log "Installing all zsh profile utilities..."
        cp -f "$zsh_src"/*.zsh "$zsh_target/"

        # Also install .p10k.zsh if it exists and we're doing "all zsh"
        if [ -f "$DOTFILES_DIR/stow/powerlevel10k/.p10k.zsh" ]; then
            log "  Copying .p10k.zsh to $HOME"
            cp -f "$DOTFILES_DIR/stow/powerlevel10k/.p10k.zsh" "$HOME/"
        fi
    fi

    local zshrc="$HOME/.zshrc"
    [ -f "$zshrc" ] || touch "$zshrc"

    # We use a marker to make the operation idempotent
    local marker="# --- dotfiles zsh utils ---"
    if ! grep -q "$marker" "$zshrc"; then
        log "  Updating $zshrc with source loop"
        cat >> "$zshrc" <<EOF

$marker
# Source all configs from ~/.zshrc.d/
if [ -d "\$HOME/.zshrc.d" ]; then
  # Use zsh globbing if possible, otherwise fallback to simple loop
  if [ -n "\$ZSH_VERSION" ]; then
    for conf in "\$HOME/.zshrc.d/"*.zsh(N); do
      source "\$conf"
    done
  else
    for conf in "\$HOME/.zshrc.d/"*.zsh; do
      [ -f "\$conf" ] && source "\$conf"
    done
  fi
fi

# Load p10k if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# ---------------------------
EOF
    else
        log "  $zshrc already contains the source loop."
    fi
    success "Zsh utilities installation complete."
}

install_fonts() {
    log "Installing Nerd Fonts..."
    
    if ! command -v curl >/dev/null; then error "curl is required."; fi
    if ! command -v unzip >/dev/null; then error "unzip is required."; fi

    local fonts=("JetBrainsMono" "FiraCode" "Meslo")
    local version="v3.3.0"
    local font_dir
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
    fi
    mkdir -p "$font_dir"

    for font in "${fonts[@]}"; do
        log "  Installing $font..."
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${font}.zip"
        local tmp_dir=$(mktemp -d)
        
        if curl -L "$font_url" -o "$tmp_dir/font.zip"; then
            unzip -q "$tmp_dir/font.zip" -d "$tmp_dir"
            find "$tmp_dir" -name "*.[ot]tf" -exec cp -f {} "$font_dir/" \;
            log "    $font installed."
        else
            log "    Failed to download $font."
        fi
        rm -rf "$tmp_dir"
    done
    
    if command -v fc-cache >/dev/null; then
        log "  Updating font cache..."
        fc-cache -f "$font_dir"
    fi
    
    success "Fonts installed."
}

install_git() {
    log "Installing git profiles..."
    local git_src="$DOTFILES_DIR/stow/git/profiles"
    local git_target="$HOME/profiles"

    log "  Copying profiles to $git_target"
    mkdir -p "$git_target"
    cp -rf "$git_src"/* "$git_target/"
    
    success "Git profiles installed."
}

sub_command="${1:-}"
shift 2>/dev/null || true
sub_target="${1:-}"

case "$sub_command" in
    skills) install_skills "$sub_target" ;;
    zsh)    install_zsh "$sub_target" ;;
    fonts)  install_fonts ;;
    git)    install_git ;;
    all)
        install_skills
        install_zsh
        install_fonts
        install_git
        ;;
    *)
        echo "Unknown install subcommand: $sub_command"
        usage
        exit 1
        ;;
esac
