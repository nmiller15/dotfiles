$DOTFILES = "c:\Code\dotfiles\powershell"

Get-ChildItem -Path $DOTFILES -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
    $ps1_sw = [System.Diagnostics.Stopwatch]::StartNew()
    . $_.FullName
    $elapsed = "{0:N3}s" -f $ps1_sw.Elapsed.TotalSeconds
    
    if ($env:BOOTSTRAP) {
        Write-Host "Sourced $_ in $elapsed"
    }
}



# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
