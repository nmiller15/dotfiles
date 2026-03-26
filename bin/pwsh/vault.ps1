# Obsidian vault navigator using fzf and nvim
# Usage: . vault.ps1 (dot-source to keep terminal in vault directory)

$VaultPath = "C:\Vault"
$InboxPath = "0 - Inbox"

# Root terminal at vault directory
Set-Location -Path $VaultPath

# Save current encoding and set UTF-8 for fzf compatibility
$prevEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Search markdown files with fzf preview
$selected = Get-ChildItem -Path $VaultPath -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName |
    fzf --preview "bat --color=always --style=plain --line-range=:100 {}" --preview-window=right:60% --height=80%

# Restore encoding
[Console]::OutputEncoding = $prevEncoding

if ($selected) {
    Start-Process -FilePath "nvim" -ArgumentList "`"$selected`"" -Wait -NoNewWindow
}
