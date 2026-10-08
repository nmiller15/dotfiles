#!/usr/bin/env zsh

selected=$(find "$HOME/Projects" "$HOME/Documents/1 - Projects" -mindepth 1 -maxdepth 1 -type d | fzf --preview "ls {}") || exit 0

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)

if [[ -n $TMUX ]]; then
    if ! tmux has-session -t="$selected_name" 2> /dev/null; then
        tmux new-session -ds "$selected_name" -c "$selected"
    fi
    tmux switch-client -t "$selected_name"
else
    tmux new-session -A -s "$selected_name" -c "$selected"
fi
