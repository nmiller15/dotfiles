# Interactive process killer using fzf
# Usage: pkill.ps1

# Save current encoding and set UTF-8 for fzf compatibility
$prevEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try {
    # Get processes with CPU and memory stats, sorted by memory usage (descending)
    $processes = Get-Process | Where-Object { $_.ProcessName -ne "Idle" } |
        Sort-Object -Property WorkingSet64 -Descending |
        ForEach-Object {
            $cpu = if ($_.CPU) { "{0,10:N1}" -f $_.CPU } else { "{0,10}" -f "0.0" }
            $mem = "{0,10:N1}" -f ($_.WorkingSet64 / 1MB)
            "{0,-8} {1,-35} {2} {3}" -f $_.Id, $_.ProcessName, $cpu, $mem
        }

    # Create header
    $header = "{0,-8} {1,-35} {2,10} {3,10}" -f "PID", "Name", "CPU(s)", "Mem(MB)"

    # Pipe to fzf for selection
    $selected = $processes | fzf --header="$header" --height=50%

    if (-not $selected) {
        exit 0
    }

    # Parse PID from selected line (first column)
    $processId = ($selected -split '\s+')[0]
    $procName = ($selected -split '\s+')[1]

    # Confirm before killing
    Write-Host "Kill process '$procName' (PID: $processId)? [y/N] " -NoNewline
    $confirm = Read-Host

    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Cancelled."
        exit 0
    }

    # Attempt graceful termination first
    try {
        Stop-Process -Id $processId -ErrorAction Stop
        Write-Host "Process '$procName' (PID: $processId) terminated."
    }
    catch {
        Write-Host "Graceful termination failed, attempting force kill..."
        try {
            Stop-Process -Id $processId -Force -ErrorAction Stop
            Write-Host "Process '$procName' (PID: $processId) force terminated."
        }
        catch {
            Write-Host "Failed to kill process: $_" -ForegroundColor Red
            exit 1
        }
    }
}
finally {
    # Restore encoding
    [Console]::OutputEncoding = $prevEncoding
}
