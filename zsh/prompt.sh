# print "Customizing ZSH prompt..."

setopt prompt_subst

ACCENT="%F{#c48282}"  # Vague func
GIT="%F{#b4d4cf}"     # Vague builtin
MUTED="%F{#878787}"   # Vague floatBorder
PATH_COLOR="%F{#c3c3d5}" # Vague property
RESET="%f"
FOLDER=""
TRI_RIGHT="▶"
GIT_SYMBOL=""

parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
  [[ -n $branch ]] && print -r -- " ${GIT}${GIT_SYMBOL} ${branch}${RESET}"
}

PROMPT="${ACCENT}%n@%m ${MUTED}${FOLDER} ${PATH_COLOR}%~\$(parse_git_branch)"$'\n'"${MUTED}${TRI_RIGHT} ${RESET}"
