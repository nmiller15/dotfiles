$HistoryFile = Join-Path $HOME ".sf_history"
$HistoryLimit = 15

# Read and clean history (filter non-existent dirs, write cleaned list back)
$historyDirs = @()
if (Test-Path $HistoryFile) {
    $historyDirs = Get-Content $HistoryFile | Where-Object { Test-Path $_ -PathType Container }
    Set-Content $HistoryFile -Value $historyDirs
}

# Build full dir list, excluding history entries to avoid duplicates
$allDirs = Get-ChildItem -Path "C:\Repos\Github", "C:\Code", "C:\Users\NMiller\OneDrive - CAB\Documents\1 - Projects" `
    -Depth 1 -Attributes Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName |
    Where-Object { $_ -notin $historyDirs }

# Combine: history first, then the rest
$combined = @($historyDirs) + @($allDirs)

$selected = $combined | fzf --preview "ls {}" --height=50%

if ($selected.Length -gt 0) {
    # Update history: prepend selection, dedup, cap at limit
    $newHistory = (@($selected) + @($historyDirs)) | Select-Object -Unique | Select-Object -First $HistoryLimit
    Set-Content $HistoryFile -Value $newHistory

    Set-Location -Path $selected
}
