# Enviroment Variables
# DOTFILES is set in PowerShell_profile.ps1


# Quick Navigation
function pdf
{ Set-Location "C:\Repos\Github" 
}
Set-Alias pd pdf

function dff
{ Set-Location $env:DOTFILES 
}
Set-Alias df dff

function ppdf
{ Set-Location "C:\Code" 
}
Set-Alias ppd ppdf

function udf
{ Set-Location $HOME 
}
Set-Alias ud udf

function ncf
{ Set-Location "C:\Users\NMiller\AppData\Local\nvim\" 
}
Set-Alias nc ncf

# Tools
Set-Alias grep rg
Set-Alias vim nvim

Remove-Item alias:curl -ErrorAction SilentlyContinue
Set-Alias curl curl.exe

