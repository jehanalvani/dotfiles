export PATH="/usr/local/sbin:$PATH"

source $HOME/.aliases


# Enable homebrew completions in zsh 

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

  autoload -Uz compinit
  compinit
fi

