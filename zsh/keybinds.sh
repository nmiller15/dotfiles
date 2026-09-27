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

function zle_sf {
    zle -I
    . sf
    zle reset-prompt
}

function zle_tmux_sessionizer {
    zle -I
    eval tmux_sessionizer.sh
    zle reset-prompt
}

zle -N zle_sf;                  bindkey -r '^G' && bindkey '^G' zle_sf
zle -N zle_reload;              bindkey -r '^A' && bindkey '^A' zle_reload
zle -N zle_reload_deploy;       bindkey -r '^B' && bindkey '^B' zle_reload_deploy
zle -N zle_tmux_sessionizer;    bindkey -r '^E' && bindkey '^E' zle_tmux_sessionizer
