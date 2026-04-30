# Reload Config
function reload
{
    param (
        [bool]$deploy
    )

    Write-Host "Linking config files..."
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    if ($deploy)
    {
        & python3 -u "$env:DOTFILES/deploy.py" | Foreach-Object { Write-Host $_ }
    }

    Write-Host "Installing tools..."
    try
    {
        & "$env:DOTFILES/bin/pwsh/install_tools.ps1"
        Write-Host "Tools installed successfully."
    } catch
    {
        Write-Host "Failed to install tools: $_"
    }
    Write-Host "Sourcing config files..."
    $env:BOOTSTRAP = "true";
    . $PROFILE

    Write-Host "Reloading services..."
    & "$HOME\OneDrive - CAB\Documents\AutoHotkey\caps-remap.ahk"
    & "$HOME\OneDrive - CAB\Documents\AutoHotkey\quick-capture.ahk"

    Remove-Item Env:BOOTSTRAP

    $elapsed = "{0:N3}s" -f $sw.Elapsed.TotalSeconds
    Write-Host "Config bootstrapped in $elapsed"
}

function install_if_missing
{
    param (
        [string]$packageName,
        [string]$installCommand
    )

    if (-not (Get-Command $packageName -ErrorAction SilentlyContinue))
    {
        Write-Host "Installing $packageName..."
        Invoke-Expression $installCommand
    } else
    {
        Write-Host "$packageName is already installed."
    }
}

function twig
{
    & "c:\Code\twig\bin\Debug\net9.0\twig.exe" @args
}

function pulse
{
    & "c:\Code\pulse\bin\Debug\net9.0\pulse.exe" @args
}
