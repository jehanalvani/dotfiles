export PATH="/usr/local/bin:$PYENV_ROOT/bin:$PATH"
#export PATH="/Users/jehan/Library/Python/3.7/bin:/usr/local/bin:$PYENV_ROOT/bin:$PATH"
# export PATH="/usr/local/sbin:$PATH"

source $HOME/.aliases

FPATH=$HOME/.zsh_functions:$FPATH


eval "$(pyenv init -)"

# Shell functions
setenv() { typeset -x "${1}${1:+=}${(@)argv[2,$#]}" }  # csh compatibility
freload() { while (( $# )); do; unfunction $1; autoload -U $1; shift; done }

# Where to look for autoloaded function definitions
fpath=($fpath ~/.zfunc)

# Autoload all shell functions from all directories in $fpath (following
# symlinks) that have the executable bit on (the executable bit is not
# necessary, but gives you an easy way to stop the autoloading of a
# particular shell function). $fpath should not be empty for this to work.
for func in $^fpath/*(N-.x:t); autoload $func


# Enable homebrew completions in zsh 

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  autoload -Uz compinit
  compinit
fi

export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
eval "$(pyenv virtualenv-init -)"

# Make permanent the required exports for the node-exporter Ansible role to complete.
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
