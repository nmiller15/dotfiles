$dotfiles = "C:\Code\dotfiles"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$links = @(
    @{ source = "$dotfiles\PowerShell_profile.ps1"; link = $PROFILE },
    @{ source = "$dotfiles\_vimrc"; link = "$HOME\_vimrc" }
    @{ source = "$dotfiles\nvim"; link = "$HOME\AppData\Local\nvim" }
    @{ source = "$dotfiles\ahk\caps-remap.ahk"; link = "$HOME\OneDrive - CAB\Documents\AutoHotkey\caps-remap.ahk" }
    @{ source = "$dotfiles\ahk\caps-remap.ahk"; link = "$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\caps-remap.ahk" }
    @{ source = "$dotfiles\ahk\add-to-things.ahk"; link = "$HOME\OneDrive - CAB\Documents\AutoHotkey\add-to-things.ahk" }
    @{ source = "$dotfiles\ahk\add-to-things.ahk"; link = "$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\add-to-things.ahk" }
    @{ source = "$dotfiles\windows_term_settings.json"; link = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" }
)

Write-Host "Linking config files..."
foreach ($entry in $links) {
    $source = $entry.source
    $link = $entry.link
    $backup = "$link.backup"


    if ((Test-Path $link) -and -not (Test-Path $backup)) {
        Rename-Item -Path $link -NewName $backup -Force
        Write-Host "Backed up: $backup"
    } 
    # Ensure parent directory exists
    $parent = Split-Path $link

    if (!(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    # Create the symlink
    if (Test-Path $source -PathType Container) {
        robocopy $source $link /E /NDL /NS /NJH /NJS /NC /R:3 /W:5
        Write-Host "Copied: $link"
    } else {
        New-Item -ItemType SymbolicLink -Path $link -Target $source -Force | Out-Null
        Write-Host "Linked: $link"
    }
}

Write-Host "Installing tools..."
try {
    & "$DOTFILES\bin\install_tools.ps1"
    Write-Host "Tools installed successfully."
} catch {
    Write-Host "Failed to install tools: $_"
}

Write-Host "Sourcing config files..."
$env:BOOTSTRAP = "true";
. $PROFILE

Write-Host "Reloading services..."
& "$HOME\OneDrive - CAB\Documents\AutoHotkey\caps-remap.ahk"
& "$HOME\OneDrive - CAB\Documents\AutoHotkey\add-to-things.ahk"

Remove-Item Env:BOOTSTRAP

$elapsed = "{0:N3}s" -f $sw.Elapsed.TotalSeconds
Write-Host "Config bootstrapped in $elapsed"
