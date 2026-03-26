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
    local space="$1"
    local appName="$2"
    local appExec="$3"

    yabai -m space --focus $space
    if ! pgrep -x "$appName" >/dev/null; then
        open -a "$appExec"
    fi
}
