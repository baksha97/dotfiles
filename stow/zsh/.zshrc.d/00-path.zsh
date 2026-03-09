[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "/opt/homebrew/anaconda3/bin" ]] && export PATH="/opt/homebrew/anaconda3/bin:$PATH"

export PNPM_HOME="$HOME/Library/pnpm"
[[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"


export ANDROID_HOME="$HOME/Library/Android/sdk"

unset JAVA_HOME