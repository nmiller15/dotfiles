# print "Customizing ZSH prompt..."

setopt prompt_subst

LOVE="%F{217}"        # rose pine moon love
PINE="%F{108}"        # rose pine moon pine
MUTED="%F{103}"       # rose pine moon muted
RESET="%f"
FOLDER=""
TRI_RIGHT="▶"
GIT_SYMBOL=""

parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
  [[ -n $branch ]] && echo " ${PINE}${GIT_SYMBOL} ${branch}${RESET}"
}

PROMPT="${LOVE}%n@%m ${MUTED}${FOLDER} %~\$(parse_git_branch)"$'\n'"${MUTED}${TRI_RIGHT} ${RESET}"
