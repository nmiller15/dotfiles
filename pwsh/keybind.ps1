Set-PSReadLineKeyHandler -Chord Ctrl+k -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+j -Function NextHistory

Set-PSReadLineKeyHandler -Chord Ctrl+e -ScriptBlock { sf.ps1 }

Set-PSReadLineKeyHandler -Chord Ctrl+a -ScriptBlock { reload 0 }
Set-PSReadLineKeyHandler -Chord Ctrl+b -ScriptBlock { reload 1 }
