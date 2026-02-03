# print "Customizing ZSH prompt..."

setopt prompt_subst

ORANGE="%F{214}"      # retro amber
BEIGE="%F{180}"       # warm beige
BROWN="%F{94}"        # earthy accent
DARKGRAY="%F{240}"    # neutral low-contrast tone
RESET="%f"

parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
  [[ -n $branch ]] && echo " ($branch)"
}

PROMPT="${ORANGE}%n@%m ${BEIGE}%~${BROWN}\$(parse_git_branch) ${DARKGRAY}& ${RESET}"

