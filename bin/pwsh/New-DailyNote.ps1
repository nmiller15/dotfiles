param(
    [Parameter(Position=0)][string]$Text
)

$VaultPath  = "C:\Vault\6 - Daily Notes"
$DateFormat = "dddd - MMMM dd, yyyy"

# Step 1 — Compute today's filename
$today     = Get-Date
$todayName = $today.ToString($DateFormat)
$todayFile = "$VaultPath\$todayName.md"

# Step 2 — Parse all existing .md files into sorted (date, name, path) records
$notes = Get-ChildItem -Path $VaultPath -Filter "*.md" | ForEach-Object {
    $baseName = $_.BaseName
    $parsed   = $null
    try {
        $parsed = [datetime]::ParseExact($baseName, $DateFormat, $null)
    } catch {
        # Skip files that don't match the expected format
    }
    if ($null -ne $parsed) {
        [PSCustomObject]@{ Date = $parsed; Name = $baseName; Path = $_.FullName }
    }
} | Sort-Object Date

# Step 3 — Find previous note (most recent file whose date is before today)
$prevNote = $notes | Where-Object { $_.Date.Date -lt $today.Date } | Select-Object -Last 1

# Step 4 — Create or append
if (-not (Test-Path $todayFile)) {
    # Build navigation line
    $prevLink = if ($prevNote) { "[[ " + $prevNote.Name + " ]]" } else { "[[  ]]" }
    $navLine  = "$prevLink  | |  [[  ]]"

    # Build file content
    $lines = @($navLine, "")
    if ($Text -ne "") {
        $lines += "- $Text"
    }
    $content = $lines -join "`n"
    Set-Content -Path $todayFile -Value $content -Encoding UTF8 -NoNewline

    # Update previous file's next link if it was created by this script
    if ($prevNote) {
        $prevContent = Get-Content -Path $prevNote.Path -Raw -Encoding UTF8
        $navPattern  = '(?m)^(\[\[ .+? \]\]  \| \|  )\[\[  \]\]$'
        if ($prevContent -match $navPattern) {
            $nextLink   = "[[ " + $todayName + " ]]"
            $newContent = $prevContent -replace $navPattern, "`${1}$nextLink"
            Set-Content -Path $prevNote.Path -Value $newContent -Encoding UTF8 -NoNewline
        }
    }
} elseif ($Text -ne "") {
    # Append bullet to existing file
    $existing = Get-Content -Path $todayFile -Raw -Encoding UTF8
    $appended = $existing.TrimEnd() + "`n- $Text"
    Set-Content -Path $todayFile -Value $appended -Encoding UTF8 -NoNewline
}
