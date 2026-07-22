# Derive DOTFILES from this script's location, resolving the symlink if present
$item = Get-Item -LiteralPath $PSCommandPath -ErrorAction SilentlyContinue
$actual = if ($item -and $item.LinkType)
{ $item.Target 
} else
{ $PSCommandPath 
}
$env:DOTFILES = Split-Path (Split-Path $actual -Parent) -Parent
$MODULES = "$env:DOTFILES\pwsh"

Get-ChildItem -Path $MODULES -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
    $ps1_sw = [System.Diagnostics.Stopwatch]::StartNew()
    if ($_.Name -ne "PowerShell_profile.ps1")
    {
        . ($_.FullName)
    }
    $elapsed = "{0:N3}s" -f $ps1_sw.Elapsed.TotalSeconds
        
    if ($env:BOOTSTRAP)
    {
        Write-Host "Sourced $_ in $elapsed"
    }
}

# Vim keybindings
Set-PSReadLineOption -EditMode Vi

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile))
{
    Import-Module "$ChocolateyProfile"
}
