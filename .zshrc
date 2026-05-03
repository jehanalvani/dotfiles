export PATH="/usr/local/bin:$PYENV_ROOT/bin:$PATH"

source $HOME/.aliases

FPATH=$HOME/.zsh_functions:$FPATH

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
  if pyenv commands | grep -q virtualenv-init; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

# Make permanent the required exports for the node-exporter Ansible role to complete.
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES


[[ $commands[kubectl] ]] && source <(kubectl completion zsh) # add autocomplete permanently to your zsh shell
export PATH="$HOME/.local/bin:$PATH"

# Private shell config (work-specific env vars, PATH additions, private tool setup)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Claude Code — per-directory account switching
# Personal account (~/.claude-personal) is the default.
# Automatically switches to MacroHealth Enterprise when inside ~/Projects/MacroHealth.
export CLAUDE_CONFIG_DIR=~/.claude-personal

_claude_config_switch() {
  if [[ "$PWD" == /Users/jehan/Projects/MacroHealth* ]]; then
    export CLAUDE_CONFIG_DIR=~/.claude-macrohealth
  else
    export CLAUDE_CONFIG_DIR=~/.claude-personal
  fi
}
autoload -U add-zsh-hook
add-zsh-hook chpwd _claude_config_switch
_claude_config_switch  # apply on shell start

eval "$(direnv hook zsh)"

codevis() {
  ANTHROPIC_API_KEY=$(op read "op://HomeLab/codevis Anthropic API Key/credential") \
    command codevis "$@"
}

eval "$(register-python-argcomplete codevis)"

# Prompt & shell enhancements
eval "$(starship init zsh)"
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
