param(
    [string]$path
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

# ─────────────────────────────────────────────────────────────────────────────
# Main Execution
# ─────────────────────────────────────────────────────────────────────────────

$uri = [System.Uri]$path
$repoName = $uri.Segments[-1]

Write-Host ""

# Create directory
Show-Step "Creating directory $gray'$repoName'$reset"
New-Item -Path $repoName -ItemType Directory -ErrorAction Stop | Out-Null
if (-not $?)
{
    Show-Failure "Failed to create directory"
    exit 1
}
Show-Success "Created $gray'$repoName'$reset"

Set-Location -Path $repoName

# Clone bare repository
Show-Step "Cloning bare repository"
git clone --bare $uri .git 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Clone failed"
    exit 1
}
Show-Success "Cloned"

# Configure remote fetch
Show-Step "Configuring remote"
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Configuration failed"
    exit 1
}
Show-Success "Configured"

# Detect main branch
Show-Step "Detecting main branch"
$isMaster = (git ls-remote --heads origin master 2>$null).Length -gt 0
$mainBranch = if ($isMaster) { "master" } else { "main" }
Show-Success "Detected $gray'$mainBranch'$reset"

# Fetch from origin
Show-Step "Fetching"
git fetch origin 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Fetch failed"
    exit 1
}
Show-Success "Fetched"

# Add worktree
Show-Step "Adding worktree $gray'$mainBranch'$reset"
git worktree add $mainBranch 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Worktree creation failed"
    exit 1
}
Show-Success "Worktree ready"

# Set upstream tracking
Show-Step "Setting upstream tracking"
Push-Location $mainBranch
git branch --set-upstream-to=origin/$mainBranch $mainBranch 2>$null | Out-Null
Pop-Location
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Upstream tracking failed"
    exit 1
}
Show-Success "Upstream configured"

Write-Host ""
Write-Host "  $cyan▸$reset $repoName/$mainBranch"
Write-Host ""

exit 0
