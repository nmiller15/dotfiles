# uv
export PATH="/Users/nolanmiller/.local/bin:$PATH"
# [[ $fpath = *dotfiles/mac/lib* ]] || fpath=(~/Projects/dotfiles/mac/lib $fpath)
# autoload ${fpath[1]}/*(:t)

function yabai_launch() {
    echo "yabai_launch"
    local space="$1"
    local appName="$2"

    yabai -m space --focus $space
    open -a $appName
}
