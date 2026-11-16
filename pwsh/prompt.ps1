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

    # Oxide palette (true color)
    $accent = "`e[38;2;0;186;170m" # teal #00baaa
    $gitColor = "`e[38;2;156;168;31m" # lime #9ca81f
    $muted = "`e[38;2;128;128;128m" # subtext1 #808080
    $pathColor = "`e[38;2;59;166;245m" # blue #3ba6f5
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
