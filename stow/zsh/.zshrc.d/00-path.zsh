[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "/opt/homebrew/anaconda3/bin" ]] && export PATH="/opt/homebrew/anaconda3/bin:$PATH"
[[ -d "$HOME/Library/Android/sdk" ]] && export ANDROID_HOME="$HOME/Library/Android/sdk"

unset JAVA_HOME
