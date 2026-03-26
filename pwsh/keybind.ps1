Set-PSReadLineKeyHandler -Chord Ctrl+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+j -Function NextHistory

Set-PSReadLineKeyHandler -Chord Ctrl+e -ScriptBlock { sf.ps1 }

Set-PSReadLineKeyHandler -Chord Ctrl+a -ScriptBlock { reload 0 }
Set-PSReadLineKeyHandler -Chord Ctrl+s -ScriptBlock { reload 1 }

Set-PsReadLineKeyHandler -Chord Ctrl+n -ScriptBlock { . vault.ps1 }
