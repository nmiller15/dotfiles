$selected = git ls-files | fzf --preview "bat --color=always --style=numbers {}"

if ($selected.Length -gt 0)
{
    git blame $selected --date=short | bat --color=always --language=log
}
