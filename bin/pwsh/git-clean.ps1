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

$startingDir = Get-Location

# Determine repository type and navigate to appropriate location
$isBareRepo = (git rev-parse --is-bare-repository 2>$null) -eq "true"
$gitPath = ".git"
$isWorktree = $false

if (-not $isBareRepo -and (Test-Path $gitPath))
{
    # Check if .git is a file (indicating a worktree) or a directory (regular repo)
    if ((Get-Item $gitPath).PSIsContainer -eq $false)
    {
        $isWorktree = $true
    }
}
elseif (-not $isBareRepo -and -not (Test-Path $gitPath))
{
    Write-Host "Not a git repository."
    exit 1
}

Write-Host ""

# If in a worktree, navigate to the parent bare repository
if ($isWorktree)
{
    $bareRepoPath = (Get-Item ".").Parent.FullName
    Show-Step "Moving to bare repo"
    Set-Location $bareRepoPath
    
    # Verify we're now in a bare repo
    $isBareRepo = (git rev-parse --is-bare-repository 2>$null) -eq "true"
    if (-not $isBareRepo)
    {
        Show-Failure "Parent directory is not a bare repository"
        Set-Location $startingDir
        exit 1
    }
    Show-Success "Moved to bare repo"
}
elseif (-not $isBareRepo)
{
    # Regular repository - ensure we're in a git repo
    if (-not (Test-Path ".git"))
    {
        Write-Host "Not a git repository."
        exit 1
    }
}

# Fetch latest remote info
Show-Step "Fetching"
git fetch --all --prune 2>$null | Out-Null
if ($LASTEXITCODE -ne 0)
{
    Show-Failure "Fetch failed"
    Set-Location $startingDir
    exit 1
}
Show-Success "Fetched"

# Discover linked worktrees only; the first record is the main (or bare) repo.
$worktrees = @()
$worktreeList = git worktree list --porcelain 2>$null
$isMainWorktree = $true
$currentPath = $null

foreach ($line in $worktreeList)
{
    if ($line -match "^worktree (.+)$")
    {
        $currentPath = $Matches[1]
    }
    elseif ($line -match "^branch refs/heads/(.+)$" -and $currentPath -and -not $isMainWorktree)
    {
        $branchName = $Matches[1]
        if ($branchName -notin @('main', 'master', 'beta'))
        {
            $worktrees += [PSCustomObject]@{
                Name = $branchName
                Path = $currentPath
            }
        }
    }
    elseif ($line -eq "")
    {
        $currentPath = $null
        $isMainWorktree = $false
    }
}

if ($worktrees.Count -eq 0)
{
    Write-Host ""
    Write-Host "  ${gray}No worktrees to clean.$reset"
    Write-Host ""
    Set-Location $startingDir
    exit 0
}

# ── Worktree prompts ──────────────────────────────────────────────────────────
$hadFailures = $false
foreach ($worktree in $worktrees)
{
    $branch = $worktree.Name
    $worktreePath = $worktree.Path
    $logOutput = git log -1 --format='%ci|%s' "refs/heads/$branch" 2>$null
    $logParts = $logOutput -split '\|', 2
    $commitMsg = $logParts[1]
    if ($commitMsg.Length -gt 50) { $commitMsg = $commitMsg.Substring(0, 47) + '...' }
    $daysAgo = (New-TimeSpan -Start ([datetime]::Parse($logParts[0])) -End (Get-Date)).Days

    $remoteRef = "refs/heads/$branch"
    $remoteRefs = git ls-remote --heads origin $remoteRef 2>$null
    if ($LASTEXITCODE -ne 0)
    {
        Show-Failure "Failed to check origin branch: $branch"
        $hadFailures = $true
        continue
    }
    $hasRemoteBranch = @($remoteRefs | Where-Object {
        ($_ -split "`t", 2)[1] -ceq $remoteRef
    }).Count -gt 0

    Write-Host ""
    Write-Host "  ${gray}┌$reset $cyan$branch$reset"
    Write-Host "  ${gray}│ $daysAgo days ago: `"$commitMsg`"$reset"
    Write-Host "  ${gray}│ Worktree: $worktreePath$reset"
    Write-Host "  ${gray}│ Remote: $(if ($hasRemoteBranch) { 'origin' } else { 'none' })$reset"
    Write-Host -NoNewline "  ${gray}└$reset Delete? ${gray}[y/N]:$reset "

    $response = Read-Host
    if ($response -notmatch '^(y|yes)$') { continue }

    Show-Step "Removing worktree"
    git worktree remove --force -- $worktreePath 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0)
    {
        Show-Failure "Failed to remove worktree: $worktreePath"
        $hadFailures = $true
        continue
    }
    if (Test-Path -LiteralPath $worktreePath)
    {
        Show-Failure "Worktree directory still exists: $worktreePath"
        $hadFailures = $true
        continue
    }
    Show-Success "Worktree removed"

    Show-Step "Deleting local branch"
    git branch -D -- $branch 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0)
    {
        Show-Failure "Failed to delete local branch: $branch"
        $hadFailures = $true
        continue
    }
    Show-Success "Local branch deleted"

    if (-not $hasRemoteBranch) { continue }

    Show-Step "Deleting origin branch"
    git push origin --delete $remoteRef 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0)
    {
        Show-Failure "Failed to delete origin branch: $branch"
        $hadFailures = $true
        continue
    }
    Show-Success "Origin branch deleted"
}

Write-Host ""
if (Test-Path -LiteralPath $startingDir) { Set-Location $startingDir }
exit [int]$hadFailures
