#!/usr/bin/env zsh

DOTFILES="$HOME/Projects/dotfiles"
. "$DOTFILES/shell/functions.sh"

bootstrap_start=$(gdate +%s%3N)

write_conf () {
    local dir=$1
    local out=$2

    echo "Writing $out"
    cat $dir/* > "$out"
    echo "# Conf written on $(gdate)" >> "$out"
}

write_conf "$DOTFILES/tmux" "$DOTFILES/.tmux.conf"
write_conf "$DOTFILES/skhd" "$DOTFILES/.skhdrc"

typeset -A links
links=(
  "$DOTFILES/.zshrc" 		"$HOME/.zshrc"
  "$DOTFILES/.zprofile" 	"$HOME/.zprofile"
  "$DOTFILES/.zshenv" 		"$HOME/.zshenv"
  "$DOTFILES/.yabairc" 		"$HOME/.yabairc"
  "$DOTFILES/.skhdrc" 		"$HOME/.skhdrc"
  "$DOTFILES/.tmux.conf" 	"$HOME/.tmux.conf"
  "$DOTFILES/eza-theme.yml"     "$HOME/.config/eza/theme.yml"
  "$DOTFILES/nvim" 		"$HOME/.config"
)

for source in "${(@k)links}"; do
  link="${links[$source]}"
  backup="$link.backup"

  if [[ -e "$link" && ! -e "$backup" ]]; then
      if [[ ! -d "$link" ]]; then
        mv -f "$link" "$backup"
        echo "Backed up: $backup"
      fi
  fi

  if [[ -d "$source" && ! -e "$link" ]]; then
      mkdir -p "$link"
  else
      parent_dir="${link:h}"
      mkdir -p "$parent_dir"
  fi 

  ln -sf "$source" "$link"
  
  if [[ -d "$source" ]]; then
      echo "Linked ${source:t} directory to $link"
  else
      echo "Linked ${source:t} to $link"
  fi
done

echo "Sourcing configuration files..."
source "$HOME/.zshenv"
MODE=bootstrap source "$HOME/.zshrc"
tmux source-file "$HOME/.tmux.conf"

echo "Installing tools..."
eval "$DOTFILES/lib/tools.sh"

echo "Restarting services..."
# brew services restart sketchybar
yabai --restart-service
skhd --restart-service 

bootstrap_end=$(gdate +%s%3N)
elapsed_ms=$(echo "$bootstrap_end - $bootstrap_start" | bc)
elapsed_sec=$(echo "scale=3; $elapsed_ms / 1000" | bc)
echo "Configurations bootstrapped in ${elapsed_sec}s"
