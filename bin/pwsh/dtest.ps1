<#
.SYNOPSIS
Runs VSTest-based dotnet tests and prints a Jest-style tree.
.EXAMPLE
dtest.ps1 --filter 'FullyQualifiedName~MyTests' --no-restore
.EXAMPLE
dtest.ps1 -ReportPath C:\Temp\results.trx
.NOTES
TRX reports are written to a temporary directory and removed after the run.
The -ReportPath option formats existing reports without invoking dotnet test.
Requires python3 (override with DTEST_PYTHON), shared with bin/bash/dtest.
Requires the VSTest runner; MTP uses different report options.
#>
param(
    [string[]]$ReportPath,
    [string]$DotnetCommand = 'dotnet',
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArguments
)

$ErrorActionPreference = 'Stop'

function Show-Stage {
    param([string]$Name, [string]$State, [bool]$Interactive)

    $symbol = switch ($State) {
        'Success' { '✓' }
        'Failure' { '✗' }
    }
    $color = switch ($State) {
        'Success' { 'Green' }
        'Failure' { 'Red' }
    }
    if ($Interactive) {
        $ansiColor = if ($State -eq 'Success') { '32' } else { '31' }
        [Console]::Out.WriteLine("`r`e[2K  `e[${ansiColor}m$symbol`e[0m `e[90m$Name`e[0m")
        return
    }
    Write-Host "  $symbol " -ForegroundColor $color -NoNewline
    Write-Host $Name -ForegroundColor DarkGray
}

function Invoke-TestRun {
    param([string[]]$Arguments, [string]$ResultsDirectory, [string]$Command)

    $job = Start-Job -WorkingDirectory (Get-Location).Path -ArgumentList (, $Arguments), $ResultsDirectory, $Command -ScriptBlock {
        param($testArgs, $directory, $dotnet)
        & $dotnet test @testArgs --results-directory $directory --logger trx --logger 'console;verbosity=quiet' 2>&1 |
            ForEach-Object { [string]$_ }
        [pscustomobject]@{ DtestExitCode = $LASTEXITCODE }
    }
    $frames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $stage = 'Preparing test run'
    $lines = [System.Collections.Generic.List[string]]::new()
    $code = $null
    $frameIndex = 0
    $interactive = -not [Console]::IsOutputRedirected
    try {
        # A single write per frame keeps the cursor and colors in sync.
        if ($interactive) { [Console]::Out.WriteLine() }
        while ($job.State -eq 'Running' -or $job.HasMoreData) {
            $transitions = [System.Collections.Generic.List[string]]::new()
            foreach ($item in @(Receive-Job -Job $job)) {
                if ($item -is [string]) {
                    $lines.Add($item)
                    $nextStage = $null
                    if ($item -match '(?i)\b(restoring|restore|up-to-date for restore)\b') { $nextStage = 'Restoring' }
                    elseif ($item -match '(?i)( -> .*\.dll\b|\bbuild (succeeded|failed)\b|\bcompiling\b)') { $nextStage = 'Building' }
                    elseif ($item -match '(?i)(test run for|starting test execution|\btest files? matched\b|\bpassed!|\bfailed!)') { $nextStage = 'Running tests' }
                    if ($nextStage -and $nextStage -ne $stage -and
                        ($transitions.Count -eq 0 -or $transitions[$transitions.Count - 1] -ne $nextStage)) {
                        $transitions.Add($nextStage)
                    }
                } elseif ($null -ne $item.DtestExitCode) {
                    $code = [int]$item.DtestExitCode
                }
            }
            foreach ($nextStage in $transitions) {
                Show-Stage -Name $stage -State Success -Interactive $interactive
                $stage = $nextStage
                $frameIndex = 0
            }
            if ($job.State -eq 'Running') {
                if ($interactive) {
                    $frame = $frames[$frameIndex % $frames.Count]
                    [Console]::Out.Write("`r`e[2K  `e[36m$frame`e[0m `e[90m$stage`e[0m")
                    $frameIndex++
                }
                Start-Sleep -Milliseconds 120
            }
        }
        if ($null -eq $code) {
            $code = 1
            $lines.Add("Test job ended without an exit code (state: $($job.State)).")
        }
        Show-Stage -Name $stage -State $(if ($code -eq 0) { 'Success' } else { 'Failure' }) -Interactive $interactive
        return [pscustomobject]@{ ExitCode = $code; Output = $lines.ToArray() }
    } finally {
        if ($job.State -eq 'Running') { Stop-Job -Job $job }
        Remove-Job -Job $job -Force
    }
}

$temporaryDirectory = $null
$exitCode = 0
try {
    $python = if ($env:DTEST_PYTHON) { $env:DTEST_PYTHON } else { 'python3' }
    if (-not (Get-Command $python -ErrorAction SilentlyContinue)) {
        throw "Python command '$python' not found. Install python3 or set DTEST_PYTHON."
    }
    $formatter = Join-Path $PSScriptRoot '..\python\dtest_report.py'
    if (-not $ReportPath) {
        if ($TestArguments | Where-Object { $_ -match '^(--logger(?:=|$)|-l$|--results-directory(?:=|$)|--list-tests$|-t$|--$)' }) {
            throw 'Do not pass --logger, --results-directory, --list-tests, or --; dtest manages its own TRX reports.'
        }
        $temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("dtest-" + [guid]::NewGuid().ToString('N'))
        [System.IO.Directory]::CreateDirectory($temporaryDirectory) | Out-Null
        # TRX's default unique filename avoids collisions across projects and frameworks.
        $run = Invoke-TestRun -Arguments $TestArguments -ResultsDirectory $temporaryDirectory -Command $DotnetCommand
        $output = $run.Output
        $exitCode = $run.ExitCode
        $ReportPath = @(Get-ChildItem -LiteralPath $temporaryDirectory -Filter '*.trx' -Recurse -File | ForEach-Object FullName)
        if ($exitCode -ne 0 -and $ReportPath.Count -gt 0) {
            # Keep build/restore errors visible, not the duplicate console test failures.
            foreach ($line in $output) {
                if ($line -match '(?i)(: error\b|\bMSBUILD\s*:\s*error\b|^\s*Build FAILED\.)') {
                    Write-Host $line -ForegroundColor DarkGray
                }
            }
        }
    }

    if ($ReportPath.Count -eq 0) {
        Write-Host 'No test results found. Check the test runner and filter.' -ForegroundColor Red
        if ($output) { foreach ($line in $output) { Write-Host $line -ForegroundColor DarkGray } }
        exit 1
    }

    & $python $formatter @ReportPath
    $reportExitCode = $LASTEXITCODE
    if ($exitCode -eq 0) { $exitCode = $reportExitCode }
    exit $exitCode
} catch {
    Write-Host "dtest: $_" -ForegroundColor Red
    exit 1
} finally {
    if ($temporaryDirectory -and (Test-Path -LiteralPath $temporaryDirectory)) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
