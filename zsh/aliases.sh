# print 'Setting up aliases...'

alias ls='eza -l --icons=auto --git --group-directories-first --header --all --time-style=relative'
alias vim='nvim'

# Nav
alias pd='cd ~/Projects/'
alias ud='cd ~'
alias nc='cd ~/.config/nvim'
alias df='cd ~/Projects/dotfiles/'

# git
alias gs='git status'
alias gp='git pull'
alias gc='git commit -m'
alias ga='git add .'

# util
alias python=python3
alias tempe='cd "$(mktemp -d)"'

# Env variables
export ASDF_DATA_DIR="/your/custom/data/dir"
