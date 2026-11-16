# print "Customizing ZSH prompt..."

setopt prompt_subst

ACCENT="%F{#00baaa}"    # Oxide teal
GIT="%F{#9ca81f}"       # Oxide lime
MUTED="%F{#808080}"     # Oxide subtext1
PATH_COLOR="%F{#3ba6f5}" # Oxide blue
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
