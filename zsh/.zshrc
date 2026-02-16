export XDG_CONFIG_HOME="$HOME/.config"

# Aliases and functions
source ~/.config/zsh/aliases.zsh
[ -f ~/.config/zsh/work.zsh ] && source ~/.config/zsh/work.zsh

# Third-party plugins
source ~/.config/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
source <(fzf --zsh)
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.config/zsh/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh

# Pure prompt
fpath+=("$(brew --prefix)/share/zsh/site-functions")
autoload -U promptinit; promptinit
zstyle :prompt:pure:path color yellow
prompt pure

# NVM
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Autojump
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# Editor
export EDITOR=nvim
alias vim="nvim"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# snowsql
alias snowsql='/Applications/SnowSQL.app/Contents/MacOS/snowsql'
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Go
export PATH="$HOME/go/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Mise
eval "$(mise activate zsh)"
