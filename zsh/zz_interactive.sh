if [ -x "$(command -v brew)" ]; then
  if [[ -r "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#606079'
  fi

  if [[ -r "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    # Vague palette for syntax highlighting; keep the theme's unbold styling.
    typeset -gA ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[default]='fg=#cdcdcd'
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#d8647e'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#6e94b2'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=#c48282'
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#c48282'
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#c48282'
    ZSH_HIGHLIGHT_STYLES[function]='fg=#c48282'
    ZSH_HIGHLIGHT_STYLES[command]='fg=#b4d4cf'
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=#b4d4cf'
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#90a0b5'
    ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#b4d4cf'
    ZSH_HIGHLIGHT_STYLES[path]='fg=#c3c3d5'
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#878787'
    ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#c3c3d5'
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=#aeaed1'
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#7e98e8'
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#9bb4bc'
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#9bb4bc'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#e8b589'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#e8b589'
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#e8b589'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#e8b589'
    ZSH_HIGHLIGHT_STYLES[assign]='fg=#cdcdcd'
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=#90a0b5'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=#606079'
    ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#cdcdcd'
    ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#cdcdcd'
  fi
fi
