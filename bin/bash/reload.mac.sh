#!/usr/bin/env zsh

source "$HOME/.zshenv"
MODE=bootstrap source "$HOME/.zshrc"
tmux source-file "$HOME/.tmux.conf"

echo "Installing tools..."
eval "$DOTFILES/bin/bash/tools.sh"

echo "Restarting services..."
aerospace reload-config
# brew services restart sketchybar
# yabai --restart-service
# skhd --restart-service 
