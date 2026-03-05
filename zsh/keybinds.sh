function zle_sf {
    zle -I
    . sf
    zle reset-prompt
}

zle -N zle_sf; bindkey '^E' zle_sf

function zle_reload {
    zle -I
    python $DOTFILES/deploy.py
    . reload.mac.sh
    zle reset-prompt

}

zle -N zle_reload; bindkey '^R' zle_reload

