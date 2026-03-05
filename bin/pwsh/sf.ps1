$selected = Get-ChildItem -Path "C:\Repos\Github", "C:\Code", "C:\Users\NMiller\OneDrive - CAB\Documents\1 - Projects" -Depth 1 -Attributes Directory |
    Select-Object -ExpandProperty FullName |
    fzf --preview "ls {}" --height=50%

if ($selected.Length -gt 0)
{
    Set-Location -Path $selected
}
