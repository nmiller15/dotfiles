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

    # Alabaster palette (true color)
    $accent = "`e[38;2;205;151;75m" # active #cd974b
    $gitColor = "`e[38;2;149;203;130m" # green #95cb82
    $muted = "`e[38;2;125;125;125m" # darker foreground #7d7d7d
    $pathColor = "`e[38;2;206;206;206m" # foreground #cecece
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
