function prompt
{
    $git = [string]::Empty
    if (Test-Path .git)
    {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch)
        {
            $git = "  $branch"
        }
    }

    # Vague palette (true color)
    $accent = "`e[38;2;196;130;130m" # func #c48282
    $gitColor = "`e[38;2;180;212;207m" # builtin #b4d4cf
    $muted = "`e[38;2;135;135;135m" # floatBorder #878787
    $pathColor = "`e[38;2;195;195;213m" # property #c3c3d5
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
