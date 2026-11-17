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

    # Noirbuddy Slate palette (true color)
    $accent = "`e[38;2;137;167;177m" # primary #89a7b1
    $gitColor = "`e[38;2;86;105;129m" # secondary #566981
    $muted = "`e[38;2;148;148;148m" # noir_5 #949494
    $pathColor = "`e[38;2;213;213;213m" # noir_2 #d5d5d5
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
