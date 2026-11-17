# print "Customizing ZSH prompt..."

setopt prompt_subst

ACCENT="%F{#89a7b1}"     # Slate primary
GIT="%F{#566981}"        # Slate secondary
MUTED="%F{#949494}"      # Noirbuddy noir_5
PATH_COLOR="%F{#d5d5d5}" # Noirbuddy noir_2
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
