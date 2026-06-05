# Dotfiles environment
if [[ -f "$HOME/Projects/dotfiles-v2/.dotfiles.env" ]]; then
    source "$HOME/Projects/dotfiles-v2/.dotfiles.env"
fi

# uv
export PATH="/Users/nolanmiller/.local/bin:$PATH"
