function zle_sf {
    zle -I
    . sf
    zle reset-prompt
}

zle -N zle_sf; bindkey '^E' zle_sf

function zle_reload {
    zle -I
    if [[ $1 == true ]]; then
        python $DOTFILES/deploy.py
    fi
    . reload.mac.sh
    zle reset-prompt
}

function zle_reload_deploy { 
    zle_reload true
}

zle -N zle_reload; bindkey '^A' zle_reload
zle -N zle_reload_deploy; bindkey '^B' zle_reload_deploy

