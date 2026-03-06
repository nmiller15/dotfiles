# Dotfiles environment
if [[ -f "$HOME/Projects/dotfiles-v2/.dotfiles.env" ]]; then
    source "$HOME/Projects/dotfiles-v2/.dotfiles.env"
fi

# uv
export PATH="/Users/nolanmiller/.local/bin:$PATH"
# [[ $fpath = *dotfiles/mac/lib* ]] || fpath=(~/Projects/dotfiles/mac/lib $fpath)
# autoload ${fpath[1]}/*(:t)
#
function yabai_launch() {
    echo "yabai_launch"
    local space="$1"
    local appName="$2"

    /opt/homebrew/bin/yabai -m space --focus "$space"
    open -a $appName
}
