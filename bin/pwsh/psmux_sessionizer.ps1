$selected = Get-ChildItem -Path "C:\Repos\Github", "C:\Code", "C:\Users\NMiller\OneDrive - CAB\Documents\1 - Projects" -Depth 1 -Attributes Directory |
    Select-Object -ExpandProperty FullName |
    fzf --preview "ls {}" --height=50%

if (-not $selected)
{ exit 0 
}

$selectedName = ($selected.BaseName -replace '\.', '_')

# Check if tmux is running
$tmuxRunning = Get-Process tmux -ErrorAction SilentlyContinue

# if (-not $env:TMUX -and -not $tmuxRunning)
# {
#     & tmux new-session -s $selectedName -c $($selected.FullName)
#     exit 0
# }

# Check if session exists
$sessionExists = & tmux has-session -t $selectedName 2>$null

if (-not $sessionExists)
{
    & tmux new-session -ds $selectedName -c $selected.FullName
}

& tmux switch-client -t $selectedName
