function prompt {
    $git = ""
    if (Test-Path .git) {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) {
            $git = " (git: $branch)"
        }
    }

    Write-Host "$env:USERNAME@$env:COMPUTERNAME " -ForegroundColor DarkMagenta -NoNewline   # purple accent
    Write-Host "$PWD" -ForegroundColor DarkGray -NoNewline                                   # muted gray
    if ($git) {
        Write-Host $git -ForegroundColor Green -NoNewline                               # softer warm tone
    }

    Write-Host ""
    Write-Host "&" -ForegroundColor DarkGray -NoNewline
    return " "
}
