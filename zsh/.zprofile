eval "$(/opt/homebrew/bin/brew shellenv zsh)"

if [[ -z "$TMUX" ]]; then
	tmux attach || tmux new-session
fi

