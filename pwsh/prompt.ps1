function prompt
{
    $previousExitCode = $global:LASTEXITCODE
    $git = [string]::Empty
    if (git rev-parse --is-inside-work-tree 2>$null)
    {
        $branch = git symbolic-ref --quiet --short HEAD 2>$null
        if ($branch)
        {
            $git = "  $branch"
        }
    }
    $global:LASTEXITCODE = $previousExitCode

    # Yugen palette (true color)
    $accent = "`e[38;2;255;190;137m" # primary #FFBE89
    $gitColor = "`e[38;2;126;171;142m" # success #7EAB8E
    $muted = "`e[38;2;169;169;169m" # color300 #A9A9A9
    $pathColor = "`e[38;2;212;212;212m" # color200 #D4D4D4
    $reset = "`e[0m"

    Write-Host "${accent}$env:USERNAME@$env:COMPUTERNAME ${muted} ${pathColor}$PWD" -NoNewline
    if ($git)
    {
        Write-Host "${gitColor}$git" -NoNewline
    }

    Write-Host "${reset}"
    Write-Host "${muted}▶${reset}" -NoNewline
    return " "
}
