param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

$index = [Array]::IndexOf($Arguments, '--results-directory')
if ($Arguments[0] -ne 'test' -or $index -lt 0) { exit 2 }
$directory = $Arguments[$index + 1]
Write-Output '  All projects are up-to-date for restore.'
Start-Sleep -Milliseconds 140
if ($env:DTEST_MOCK_FAILURE -eq 'build') {
    Write-Output 'Build FAILED.'
    exit 1
}
Write-Output '  Example.Tests -> Example.Tests.dll'
Start-Sleep -Milliseconds 140
Write-Output 'Test run for Example.Tests.dll'
Start-Sleep -Milliseconds 140
if ($env:DTEST_MOCK_FAILURE -eq '1') {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'dtest-sample.trx') -Destination (Join-Path $directory 'results.trx')
    exit 1
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'dtest-passing.trx') -Destination (Join-Path $directory 'results.trx')
