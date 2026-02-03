function yabai_launch() {
    local space="$1"
    local appName="$2"
    local appExec="$3"

    yabai -m space --focus $space
    if ! pgrep -x "$appName" >/dev/null; then
        open -a "$appExec"
    fi
}
