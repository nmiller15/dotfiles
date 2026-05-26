function prompt
{
    $git = ""
    if (Test-Path .git)
    {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch)
        {
            $git = "  $branch"
        }
    }

    # Rose Pine Moon colors
    $love = "`e[38;5;217m"    # rose pine moon love
    $pine = "`e[38;5;108m"    # rose pine moon pine
    $muted = "`e[38;5;103m"   # rose pine moon muted
    $reset = "`e[0m"

    Write-Host "${love}$env:USERNAME@$env:COMPUTERNAME ${muted} $PWD" -NoNewline
    if ($git)
    {
        Write-Host "${pine}$git" -NoNewline
    }

    Write-Host "${reset}"
    Write-Host "${muted}▶${reset}" -NoNewline
    return " "
}
