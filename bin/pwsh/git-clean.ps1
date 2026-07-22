[CmdletBinding()]
param(
    [Alias("r")]
    [switch]$IncludeRemote,
    [Alias("a")]
    [switch]$AllAuthors
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

# Build worktree lookup table (branch name -> worktree path)
$worktrees = @{}
$worktreeList = git worktree list --porcelain 2>$null
$currentPath = $null

foreach ($line in $worktreeList)
{
    if ($line -match "^worktree (.+)$")
    {
        $currentPath = $Matches[1]
    }
    elseif ($line -match "^branch refs/heads/(.+)$" -and $currentPath)
    {
        $branchName = $Matches[1]
        $worktrees[$branchName] = $currentPath
        $currentPath = $null
    }
    elseif ($line -eq "")
    {
        $currentPath = $null
    }
}

# Get current git user email for authorship filtering
$currentUserEmail = (git config user.email 2>$null).Trim()

# Get all local branches except main/master/beta
$branches = git branch --no-column --format='%(refname:short)|%(upstream:short)' |
    Where-Object { $_ } |
    ForEach-Object {
        $parts = $_ -split '\|', 2
        $name = $parts[0]
        $upstream = $parts[1]
        if ($name -in @("main","master","beta")) { Write-Verbose "Skipping '$name': protected branch"; return }
        $logOutput = git log -1 --format="%ci|%ae|%an|%s" $name 2>$null
        if (-not $logOutput) { Write-Verbose "Skipping '$name': no log output"; return }
        $logParts = $logOutput -split '\|', 4
        [PSCustomObject]@{
            Name          = $name
            Upstream      = $upstream
            IsRemoteOnly  = $false
            Date          = [datetime]::Parse($logParts[0])
            CommitMsg     = $logParts[3]
            AuthorEmail   = $logParts[1].Trim()
            AuthorName    = $logParts[2].Trim()
            IsCurrentUser = $logParts[1].Trim() -eq $currentUserEmail
        }
    } |
    Where-Object { $_ }

# If -IncludeRemote, also collect remote-only branches (no local counterpart)
$remoteOnlyBranches = @()
if ($IncludeRemote)
{
    $allLocalNames = git branch --no-column --format='%(refname:short)' | Where-Object { $_ }

    $remoteOnlyBranches = git branch -r --no-column --format='%(refname:short)' |
        Where-Object { $_ -and $_ -notmatch '(->|HEAD)' } |
        ForEach-Object {
            $refName = $_
            $name = $_ -replace '^origin/', ''
            if ($name -in @("main","master","beta")) { Write-Verbose "Skipping remote '$name': protected branch"; return }
            if ($name -in $allLocalNames) { return }
            $logOutput = git log -1 --format="%ci|%ae|%an|%s" $refName 2>$null
            if (-not $logOutput) { Write-Verbose "Skipping remote '$name': no log output"; return }
            $logParts = $logOutput -split '\|', 4
            if (-not $AllAuthors -and $logParts[1].Trim() -ne $currentUserEmail) { Write-Verbose "Skipping remote '$name': author '$($logParts[1].Trim())' != '$currentUserEmail'"; return }
            [PSCustomObject]@{
                Name          = $name
                Upstream      = $refName
                IsRemoteOnly  = $true
                Date          = [datetime]::Parse($logParts[0])
                CommitMsg     = $logParts[3]
                AuthorEmail   = $logParts[1].Trim()
                AuthorName    = $logParts[2].Trim()
                IsCurrentUser = $logParts[1].Trim() -eq $currentUserEmail
            }
        } |
        Where-Object { $_ }
}

# Combine local and remote-only branches, sorted oldest-first
$allBranches = (@($branches) + @($remoteOnlyBranches)) |
    Where-Object { $_ } |
    Sort-Object Date

if (-not $allBranches -or $allBranches.Count -eq 0)
{
    Write-Host ""
    Write-Host "  ${gray}No branches to clean.$reset"
    Write-Host ""
    Set-Location $startingDir
    exit 0
}

foreach ($branchInfo in $allBranches)
{
    $branch = $branchInfo.Name
    $upstream = $branchInfo.Upstream
    $isRemoteOnly = $branchInfo.IsRemoteOnly

    $commitMsg = $branchInfo.CommitMsg
    if ($commitMsg.Length -gt 50) { $commitMsg = $commitMsg.Substring(0, 47) + "..." }
    $daysAgo = (New-TimeSpan -Start $branchInfo.Date -End (Get-Date)).Days

    # Build box-style prompt
    $worktreePath = if (-not $isRemoteOnly) { $worktrees[$branch] } else { $null }

    Write-Host ""
    Write-Host "  ${gray}┌$reset $cyan$branch$reset"
    Write-Host "  ${gray}│ $daysAgo days ago: `"$commitMsg`"$reset"
    if (-not $branchInfo.IsCurrentUser)
    {
        Write-Host "  ${gray}│ Author: $($branchInfo.AuthorName) <$($branchInfo.AuthorEmail)>$reset"
    }
    if ($isRemoteOnly)
    {
        Write-Host "  ${gray}│ Remote only$reset"
    }
    elseif ($upstream)
    {
        Write-Host "  ${gray}│ Remote: $upstream$reset"
    }
    else
    {
        Write-Host "  ${gray}│ Local only$reset"
    }
    if ($worktreePath)
    {
        Write-Host "  ${gray}│ Worktree: $worktreePath$reset"
    }
    Write-Host -NoNewline "  ${gray}└$reset Delete? ${gray}[y/N]:$reset "
    
    $response = Read-Host
    if ($response -match '^(y|yes)$')
    {
        # Remove worktree if it exists (local branches only)
        if ($worktreePath)
        {
            Show-Step "Removing worktree"
            git worktree remove --force $worktreePath 2>$null | Out-Null
            
            # If directory still exists, remove it manually
            if (Test-Path $worktreePath)
            {
                Remove-Item -Path $worktreePath -Recurse -Force -ErrorAction SilentlyContinue
            }
            Show-Success "Worktree removed"
        }

        Show-Step "Deleting branch"
        if ($isRemoteOnly -or $upstream)
        {
            git push origin --delete $branch 2>$null | Out-Null
        }
        if (-not $isRemoteOnly)
        {
            git branch -D $branch 2>$null | Out-Null
        }
        Show-Success "Branch deleted"
    }
}

Write-Host ""
Set-Location $startingDir
exit 0
