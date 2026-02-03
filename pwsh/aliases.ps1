# Enviroment Vairables
$env:DOTFILES = "C:\Code\dotfiles"

# Quick Navigation
function pdf { Set-Location "C:\Repos\Github" }
Set-Alias pd pdf

function dff { Set-Location $env:DOTFILES }
Set-Alias df dff

function ppdf { Set-Location "C:\Code" }
Set-Alias ppd ppdf

Set-Alias ud udf

function ncf { Set-Location "C:\Users\NMiller\AppData\Local\nvim\" }
Set-Alias nc ncf

# Tools
Set-Alias grep rg
Set-Alias vim nvim
Set-Alias tldr "C:\Users\NMiller\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts\tldr.exe"

Remove-Item alias:curl -ErrorAction SilentlyContinue
Set-Alias curl curl.exe

Set-Alias add-to-things "C:\Code\dotfiles\bin\add-to-things"
