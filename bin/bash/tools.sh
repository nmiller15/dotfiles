. ~/Projects/dotfiles/shell/functions.sh

install_if_missing fzf "brew install fzf" 
install_if_missing wget "brew install wget"
install_if_missing jq "brew install jq" 
install_if_missing node "brew install node"
install_if_missing npm "brew install npm"
if ! brew list --formula zsh-autosuggestions >/dev/null 2>&1; then
    brew install zsh-autosuggestions
else
    echo "zsh-autosuggestions is already installed."
fi

if ! brew list --formula zsh-syntax-highlighting >/dev/null 2>&1; then
    brew install zsh-syntax-highlighting
else
    echo "zsh-syntax-highlighting is already installed."
fi
# install_if_missing yabai "brew install koekeishiya/formulae/yabai && yabai --start-service"
# install_if_missing sketchybar "brew install FelixKratz/formulae/sketchybar"
# install_if_missing skhd "brew install koekeishiya/formulae/skhd && skhd --start-service"
install_if_missing tldr "npm install -g tldr"
install_if_missing gcc "brew install gcc"
install_if_missing eza "brew install eza"
install_if_missing scc "brew install scc"
install_if_missing bat "brew install bat"
install_if_missing entr "brew install entr"
install_if_missing hyperfine "brew install hyperfine"
install_if_missing procs "brew install procs"
install_if_missing navi "brew install navi"
install_if_missing just "brew install just"
install_if_missing bpytop "brew install bpytop"
install_if_missing aerospace "brew install --cask nikitabobko/tap/aerospace"
install_if_missing matter "curl -fsSL https://cli.getmatter.com/install.sh | sh"
install_if_missing tree-sitter "brew install tree-sitter-cli"
