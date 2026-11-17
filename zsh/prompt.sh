# print "Customizing ZSH prompt..."

setopt prompt_subst

ACCENT="%F{#cd974b}"     # Alabaster active
GIT="%F{#95cb82}"        # Alabaster green
MUTED="%F{#7d7d7d}"      # Alabaster darker foreground
PATH_COLOR="%F{#cecece}" # Alabaster foreground
RESET="%f"
FOLDER=""
TRI_RIGHT="▶"
GIT_SYMBOL=""

parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || return
  [[ -n $branch ]] && print -r -- " ${GIT}${GIT_SYMBOL} ${branch}${RESET}"
}

PROMPT="${ACCENT}%n@%m ${MUTED}${FOLDER} ${PATH_COLOR}%~\$(parse_git_branch)"$'\n'"${MUTED}${TRI_RIGHT} ${RESET}"
