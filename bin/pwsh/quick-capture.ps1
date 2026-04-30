param(
    [Parameter(Position=0)][string]$inputText
)

if ($inputText -match "^/m\s+(.+)$") {
    # Extract URL and save to Matter
    $url = $matches[1].Trim()
    & matter items save --url $url
} else {
    # Pass to AddToThings.ps1
    & "$env:DOTFILES\bin\pwsh\AddToThings.ps1" $inputText
}
