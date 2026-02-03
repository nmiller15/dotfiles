
eval "$(/usr/local/bin/brew shellenv)"

if [[ -z "$TMUX" ]]; then
	tmux attach || tmux new-session
fi

