export PATH="/usr/local/sbin:$PATH"

source $HOME/.aliases

FPATH=$HOME/.zsh_functions:$FPATH

# Autoload some functions

autoload imgur-dl-unpack


# Enable homebrew completions in zsh 

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  autoload -Uz compinit
  compinit
fi

