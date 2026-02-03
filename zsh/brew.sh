# print "Setting up Homebrew..."

# Homebrew (if installed) - Ensure it takes precedence
if [ -x "$(command -v brew)" ]; then
  eval "$($(command -v brew) shellenv)"
fi

# Enable auto-completion and syntax highlighting if installed
[[ -r "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
