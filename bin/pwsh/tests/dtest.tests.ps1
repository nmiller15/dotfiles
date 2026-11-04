$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot '..\dtest.ps1'
$fixture = Join-Path $PSScriptRoot 'dtest-sample.trx'

$output = & pwsh -NoProfile -File $script -ReportPath $fixture 6>&1 | Out-String
if ($LASTEXITCODE -ne 1) { throw "Expected failing tests to exit 1, got $LASTEXITCODE" }
foreach ($expected in @('Example.Tests.CalculatorTests', 'Passes(2)', 'Fails',
        'Expected: 2', 'Example.Tests.OtherTests', 'Pending', 'OtherFails',
        'Tests:', 'Passed:  1', 'Failed:  2', 'Skipped: 1',
        'Total:   4', 'Classes: 2')) {
    if (-not $output.Contains($expected)) { throw "Missing output: $expected" }
}
if ($output -match '[│├└─]' -or $output -notmatch '(?m)^  [^\r\n]+ Passes\(2\)' -or
    $output -notmatch '(?m)^  [^\r\n]+ Fails' -or $output -notmatch '(?m)^  [^\r\n]+ Pending') {
    throw 'Expected a plain list with outcome markers and no box-drawing characters.'
}
$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
    $bashOutput = & bash (Join-Path $PSScriptRoot '..\..\bash\dtest') --report $fixture 2>&1 | Out-String
    if ($LASTEXITCODE -ne 1 -or $output.Trim() -ne $bashOutput.Trim()) {
        throw 'PowerShell and Bash must display the same report.'
    }
}
$failuresIndex = $output.IndexOf('Failures:')
$summaryIndex = $output.IndexOf('Tests:', $failuresIndex)
if ($failuresIndex -lt 0 -or $summaryIndex -le $failuresIndex -or
    $output.IndexOf('Example.Tests.OtherTests', $failuresIndex) -lt 0 -or
    $output.IndexOf('Example.Tests.CalculatorTests.Fails', $failuresIndex) -lt 0 -or
    $output.IndexOf('Example.Tests.OtherTests.OtherFails', $failuresIndex) -lt 0 -or
    $output.IndexOf('Expected: 2') -lt $failuresIndex -or
    $output.IndexOf('Other failure') -lt $failuresIndex -or
    $output.IndexOf('Other failure') -ge $summaryIndex -or
    ([regex]::Matches($output, 'Expected: 2')).Count -ne 1 -or
    ([regex]::Matches($output, 'Other failure')).Count -ne 1) {
    throw 'Each failure must have a title in the list and details only above the summary.'
}

$output = & pwsh -NoProfile -File $script -ReportPath (Join-Path $PSScriptRoot 'missing.trx') 2>&1 | Out-String
if ($LASTEXITCODE -ne 1 -or -not $output.Contains('dtest:')) {
    throw 'Missing TRX should report an error and fail.'
}

$output = & pwsh -NoProfile -File $script -ReportPath (Join-Path $PSScriptRoot 'dtest-passing.trx') 6>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or -not $output.Contains('Passed:  1') -or
    -not $output.Contains('Failed:  0') -or -not $output.Contains('Total:   1')) {
    throw 'All-passing TRX should report success.'
}

$reports = @($fixture, (Join-Path $PSScriptRoot 'dtest-passing.trx'))
$output = & pwsh -NoProfile -CommandWithArgs '& $args[0] -ReportPath @($args[1], $args[2]); exit $LASTEXITCODE' $script $reports[0] $reports[1] 6>&1 | Out-String
if ($LASTEXITCODE -ne 1 -or -not $output.Contains('Passed:  2') -or
    -not $output.Contains('Failed:  2') -or -not $output.Contains('Total:   5')) {
    throw 'Multiple TRX files should be aggregated by the shared formatter.'
}

$oldPython = $env:DTEST_PYTHON
try {
    $env:DTEST_PYTHON = 'not-a-real-python-command-dtest'
    $output = & pwsh -NoProfile -File $script -ReportPath $fixture 6>&1 | Out-String
    if ($LASTEXITCODE -ne 1 -or -not $output.Contains('Install python3 or set DTEST_PYTHON')) {
        throw 'Missing Python should produce an actionable error.'
    }
} finally {
    if ($null -eq $oldPython) { Remove-Item Env:DTEST_PYTHON -ErrorAction SilentlyContinue }
    else { $env:DTEST_PYTHON = $oldPython }
}

try {
    $mockDotnet = Join-Path $PSScriptRoot 'mock-dotnet.cmd'
    $output = & pwsh -NoProfile -File $script -DotnetCommand $mockDotnet 6>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Mock passing run exited $LASTEXITCODE" }
    foreach ($stage in @('Preparing test run', 'Restoring', 'Building', 'Running tests')) {
        if (-not $output.Contains($stage)) { throw "Missing stage: $stage" }
    }
    $env:DTEST_MOCK_FAILURE = '1'
    $output = & pwsh -NoProfile -File $script -DotnetCommand $mockDotnet 6>&1 | Out-String
    if ($LASTEXITCODE -ne 1 -or -not $output.Contains('Failed:  2') -or
        -not $output.Contains('Failures:')) {
        throw 'Mock failing run should display results and exit 1.'
    }
    $env:DTEST_MOCK_FAILURE = 'build'
    $output = & pwsh -NoProfile -File $script -DotnetCommand $mockDotnet 6>&1 | Out-String
    if ($LASTEXITCODE -ne 1 -or -not $output.Contains('Build FAILED.') -or
        -not $output.Contains('No test results found.')) {
        throw 'Mock build failure should show its error and exit 1.'
    }
} finally {
    Remove-Item Env:DTEST_MOCK_FAILURE -ErrorAction SilentlyContinue
}

Write-Host 'dtest offline checks passed.' -ForegroundColor Green
