if [ -x "$(command -v brew)" ]; then
  if [[ -r "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60'
  fi

  if [[ -r "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    # Balanced Rose Pine Moon palette for zsh-syntax-highlighting.
    typeset -gA ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[default]='fg=188'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=217,bold'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=108,bold'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=221,bold'
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=221,bold'
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=223,bold'
    ZSH_HIGHLIGHT_STYLES[function]='fg=221,bold'
    ZSH_HIGHLIGHT_STYLES[command]='fg=221,bold'
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=223,bold'
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=103'
    ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=221,bold'
    ZSH_HIGHLIGHT_STYLES[path]='fg=103'
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=103'
    ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=103'
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=108'
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=146'
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=223'
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=223'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=229'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=229'
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=229'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=229'
    ZSH_HIGHLIGHT_STYLES[assign]='fg=188'
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=223'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=103'
    ZSH_HIGHLIGHT_STYLES[named-fd]='fg=188'
    ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=188'
  fi
fi
