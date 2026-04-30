param(
    [string]$Name
)

$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────────────────────────────────────
# ANSI Output Helpers
# ─────────────────────────────────────────────────────────────────────────────

$script:gray = "`e[90m"
$script:cyan = "`e[36m"
$script:green = "`e[32m"
$script:red = "`e[31m"
$script:reset = "`e[0m"
$script:clearLine = "`e[2K"
$script:cursorUp = "`e[1A"

function Show-Step
{
    param([string]$Message)
    Write-Host "  $gray●$reset $Message"
}

function Show-Success
{
    param([string]$Message)
    Write-Host "$cursorUp$clearLine  $green✓$reset $Message"
}

function Show-Failure
{
    param([string]$Message)
    Write-Host "$cursorUp$clearLine  $red✗$reset $Message"
}

function Invoke-WithSpinner
{
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message,
        [string]$WorkingDirectory
    )

    $spinnerFrames = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')

    $job = Start-Job -ScriptBlock $ScriptBlock -ArgumentList $WorkingDirectory

    $i = 0
    Write-Host "  $cyan$($spinnerFrames[0])$reset $Message" -NoNewline

    while ($job.State -eq 'Running')
    {
        $frame = $spinnerFrames[$i % $spinnerFrames.Length]
        Write-Host "`r  $cyan$frame$reset $Message" -NoNewline
        Start-Sleep -Milliseconds 80
        $i++
    }

    Write-Host "`r$clearLine" -NoNewline

    $result = Receive-Job -Job $job
    $exitCode = $job.ChildJobs[0].JobStateInfo.Reason.ExitCode
    Remove-Job -Job $job

    return @{
        Output = $result
        ExitCode = $exitCode
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Core Functions
# ─────────────────────────────────────────────────────────────────────────────

function IsLinkedWorktree
{
    $gitDir = git rev-parse --git-dir
    $commonDir = git rev-parse --git-common-dir

    return $gitDir.Trim() -ne $commonDir.Trim()
}

function Get-DefaultBranch
{
    if (Test-Path master -PathType Container)
    {
        return "master"
    } else
    {
        return "main"
    }
}

function ErrorOut
{
    param(
        [string]$Message
    )
    Write-Host "`e[31mERROR:`e[0m`e[90m $Message`e[0m"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Execution
# ─────────────────────────────────────────────────────────────────────────────

$startingDir = Get-Location

if ([string]::IsNullOrWhiteSpace($Name))
{
    Write-Host "So.. are you gonna name it.. or?"
    exit 1
}

if (IsLinkedWorktree)
{
    Write-Host "You ain't in the right directory, buddy."
    exit 1
}

if (Test-Path $Name -PathType Container)
{
    Write-Host "That's literally already a thing here, bro."
    exit 1
}

$main = Get-DefaultBranch
if ($null -eq $main)
{
    ErrorOut "No main branch found."
    exit 1
}

if (-not (Test-Path $main -PathType Container))
{
    ErrorOut "No '$main' branch found."
    exit 1
}

Write-Host ""

# Enter main branch
Show-Step "Entering $gray$main$reset branch"
Set-Location $main 2>$null
if (-not $?)
{
    Show-Failure "Couldn't enter $main branch"
    Set-Location $startingDir
    exit 1
}
Show-Success "Entered $gray$main$reset branch"

# Reset branch
Show-Step "Resetting branch"
git reset HEAD --hard 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Reset failed"
    Set-Location $startingDir
    exit 1
}
Show-Success "Branch reset"

# Pull latest
Show-Step "Pulling latest"
git pull 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Pull failed"
    Set-Location $startingDir
    exit 1
}
Show-Success "Up to date"

# Create worktree
Set-Location .. 2>$null
Show-Step "Creating worktree $gray$Name$reset"
git worktree add $Name -b $Name $main 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Worktree creation failed"
    Set-Location $startingDir
    exit 1
}
Show-Success "Worktree $gray$Name$reset created"

# Build solution
$worktreePath = Join-Path $startingDir $Name
$buildResult = Invoke-WithSpinner -ScriptBlock {
    param($dir)
    Set-Location $dir
    $output = dotnet build 2>&1
    return @{
        Output = $output
        ExitCode = $LASTEXITCODE
    }
} -Message "Building" -WorkingDirectory $worktreePath

if ($buildResult.Output.ExitCode -ne 0)
{
    Write-Host "  $red✗$reset Build failed"
    $errors = $buildResult.Output.Output -split "`n" | Where-Object { $_ -match ': error ' }
    foreach ($err in $errors)
    {
        $trimmed = $err.Trim()
        if ($trimmed)
        {
            Write-Host "    $gray$trimmed$reset"
        }
    }
}
else
{
    Write-Host "  $green✓$reset Build succeeded"
}

Write-Host ""
Write-Host "  $cyan▸$reset $Name"
Write-Host ""

Set-Location $startingDir
exit 0
