param(
    [Parameter(Position=0)][string]$inputText
)

if ($inputText -match "^/m\s+(.+)$") {
    # Extract URL and save to Matter
    $url = $matches[1].Trim()
    & matter items save --url $url
} elseif ($inputText -match "^/q\s*(.*)$") {
    # Create or append to today's daily note
    & "$env:DOTFILES\bin\pwsh\New-DailyNote.ps1" $matches[1].Trim()
} else {
    # Pass to AddToThings.ps1
    & "$env:DOTFILES\bin\pwsh\AddToThings.ps1" $inputText
}
