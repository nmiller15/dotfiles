# Reload Config
function reload { . "$env:DOTFILES\bootstrap.ps1" }

function install_if_missing {
    param (
        [string]$packageName,
        [string]$installCommand
    )

    if (-not (Get-Command $packageName -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $packageName..."
        Invoke-Expression $installCommand
    } else {
        Write-Host "$packageName is already installed."
    }
}

function twig {
    & "c:\Code\twig\bin\Debug\net9.0\twig.exe" @args
}

function pulse {
    & "c:\Code\pulse\bin\Debug\net9.0\pulse.exe" @args
}
