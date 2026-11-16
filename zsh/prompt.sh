# print "Customizing ZSH prompt..."

setopt prompt_subst

ACCENT="%F{#FFBE89}"     # Yugen primary
GIT="%F{#7EAB8E}"        # Yugen success
MUTED="%F{#A9A9A9}"      # Yugen color300
PATH_COLOR="%F{#D4D4D4}" # Yugen color200
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
