install_if_missing() {
    local cmd="$1"
    local install_cmd="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing $cmd..."
        eval "$install_cmd"
    else
        echo "$cmd is already installed."
    fi
}
