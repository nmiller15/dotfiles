param(
    [Parameter(Position = 0)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        $reposPath = "C:\Repos\Github"
        Get-ChildItem -Path $reposPath -Directory -ErrorAction SilentlyContinue |
            Where-Object {
                (Test-Path (Join-Path $_.FullName "master") -PathType Container) -or
                (Test-Path (Join-Path $_.FullName "main") -PathType Container)
            } |
            Select-Object -ExpandProperty Name |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { $_ }
    })]
    [string]$Repo,

    [Parameter(Position = 1)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        $reposPath = "C:\Repos\Github"
        $repoName = $fakeBoundParameters['Repo']
        if ([string]::IsNullOrWhiteSpace($repoName)) { return }
        
        $repoPath = Join-Path $reposPath $repoName
        if (-not (Test-Path $repoPath -PathType Container)) { return }
        
        Get-ChildItem -Path $repoPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^\.' } |
            Select-Object -ExpandProperty Name |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { $_ }
    })]
    [string]$Tree,

    [Parameter(Position = 2)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        
        $reposPath = "C:\Repos\Github"
        $repoName = $fakeBoundParameters['Repo']
        if ([string]::IsNullOrWhiteSpace($repoName)) { return }
        
        $repoPath = Join-Path $reposPath $repoName
        if (-not (Test-Path $repoPath -PathType Container)) { return }
        
        # Determine tree path
        $treeName = $fakeBoundParameters['Tree']
        if ([string]::IsNullOrWhiteSpace($treeName))
        {
            # Use default branch
            if (Test-Path (Join-Path $repoPath "master") -PathType Container)
            {
                $treeName = "master"
            }
            elseif (Test-Path (Join-Path $repoPath "main") -PathType Container)
            {
                $treeName = "main"
            }
            else { return }
        }
        
        $treePath = Join-Path $repoPath $treeName
        if (-not (Test-Path $treePath -PathType Container)) { return }
        
        # Find runnable projects
        Get-ChildItem -Path $treePath -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                ($content -match 'Microsoft\.NET\.Sdk\.Web') -or ($content -match '<OutputType>Exe</OutputType>')
            } |
            Select-Object -ExpandProperty BaseName |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { $_ }
    })]
    [string]$Project,

    [Parameter()]
    [Alias("t")]
    [switch]$SelectTree,

    [Parameter()]
    [Alias("p")]
    [switch]$SelectProject,

    [Parameter()]
    [Alias("tp", "pt")]
    [switch]$TreeProject,

    [Parameter()]
    [Alias("np")]
    [switch]$NoPull,

    [Parameter()]
    [Alias("v")]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

# Handle combined flag - sets both select switches to trigger fzf
if ($TreeProject)
{
    $SelectTree = $true
    $SelectProject = $true
}

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

$script:ReposPath = "C:\Repos\Github"

# ─────────────────────────────────────────────────────────────────────────────
# ANSI Output Helpers
# ─────────────────────────────────────────────────────────────────────────────

$script:gray = "`e[90m"
$script:cyan = "`e[36m"
$script:green = "`e[32m"
$script:red = "`e[31m"
$script:reset = "`e[0m"

$script:spinnerFrames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')

function Show-Info
{
    param([string]$Message)
    Write-Host "  $cyan>$reset $Message"
}

function Show-Success
{
    param([string]$Message)
    Write-Host "  $green>$reset $Message"
}

function ErrorOut
{
    param([string]$Message)
    Write-Host "`e[31mERROR:`e[0m`e[90m $Message`e[0m"
}

# ─────────────────────────────────────────────────────────────────────────────
# Core Functions
# ─────────────────────────────────────────────────────────────────────────────

function Get-WorktreeRepos
{
    Get-ChildItem -Path $script:ReposPath -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            (Test-Path (Join-Path $_.FullName "master") -PathType Container) -or
            (Test-Path (Join-Path $_.FullName "main") -PathType Container)
        } |
        Select-Object -ExpandProperty Name
}

function Get-DefaultBranch
{
    param([string]$RepoPath)
    
    if (Test-Path (Join-Path $RepoPath "master") -PathType Container)
    {
        return "master"
    }
    elseif (Test-Path (Join-Path $RepoPath "main") -PathType Container)
    {
        return "main"
    }
    return $null
}

function Get-AvailableWorktrees
{
    param([string]$RepoPath)
    
    Get-ChildItem -Path $RepoPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^\.' } |
        Select-Object -ExpandProperty Name
}

function Find-RunnableProjects
{
    param([string]$TreePath)
    
    $csprojFiles = Get-ChildItem -Path $TreePath -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue
    $runnableProjects = @()
    
    foreach ($csproj in $csprojFiles)
    {
        $content = Get-Content $csproj.FullName -Raw -ErrorAction SilentlyContinue
        # Web SDK projects
        if ($content -match 'Microsoft\.NET\.Sdk\.Web')
        {
            $runnableProjects += $csproj
        }
        # Console apps (have OutputType Exe)
        elseif ($content -match '<OutputType>Exe</OutputType>')
        {
            $runnableProjects += $csproj
        }
    }
    
    return $runnableProjects
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Execution
# ─────────────────────────────────────────────────────────────────────────────

# Validate repo argument
if ([string]::IsNullOrWhiteSpace($Repo))
{
    $availableRepos = Get-WorktreeRepos
    Write-Host ""
    ErrorOut "No repository specified."
    Write-Host ""
    Write-Host "  ${gray}Available worktree repos:$reset"
    foreach ($r in $availableRepos)
    {
        Write-Host "    $cyan>$reset $r"
    }
    Write-Host ""
    exit 1
}

# Validate repo exists
$repoPath = Join-Path $script:ReposPath $Repo
if (-not (Test-Path $repoPath -PathType Container))
{
    $availableRepos = Get-WorktreeRepos
    Write-Host ""
    ErrorOut "Repository '$Repo' not found."
    Write-Host ""
    Write-Host "  ${gray}Available worktree repos:$reset"
    foreach ($r in $availableRepos)
    {
        Write-Host "    $cyan>$reset $r"
    }
    Write-Host ""
    exit 1
}

# Check if it's a worktree repo
$defaultBranch = Get-DefaultBranch -RepoPath $repoPath
if ($null -eq $defaultBranch)
{
    Write-Host ""
    ErrorOut "'$Repo' is not a worktree-based repository."
    Write-Host "  ${gray}Expected a 'master' or 'main' subdirectory.$reset"
    Write-Host ""
    exit 1
}

# Determine which tree to use
if ($SelectTree)
{
    # -t flag: show fzf picker
    $availableTrees = Get-AvailableWorktrees -RepoPath $repoPath
    $treeName = $availableTrees | fzf --height=50%
    
    if ([string]::IsNullOrWhiteSpace($treeName))
    {
        # User cancelled fzf
        exit 0
    }
}
elseif ([string]::IsNullOrWhiteSpace($Tree))
{
    # Not provided: use default branch
    $treeName = $defaultBranch
}
else
{
    # Positional value provided: use specified tree
    $treeName = $Tree
}

# Validate tree exists
$treePath = Join-Path $repoPath $treeName
if (-not (Test-Path $treePath -PathType Container))
{
    $availableTrees = Get-AvailableWorktrees -RepoPath $repoPath
    Write-Host ""
    ErrorOut "Worktree '$treeName' not found in '$Repo'."
    Write-Host ""
    Write-Host "  ${gray}Available worktrees:$reset"
    foreach ($t in $availableTrees)
    {
        Write-Host "    $cyan>$reset $t"
    }
    Write-Host ""
    exit 1
}

# Pull latest if on default branch (unless -NoPull specified)
if (-not $NoPull -and ($treeName -eq "master" -or $treeName -eq "main"))
{
    Show-Info "Pulling latest on $gray$treeName$reset..."
    
    $pullOutput = git -C $treePath pull 2>&1
    
    if ($LASTEXITCODE -ne 0)
    {
        ErrorOut "Failed to pull latest on '$treeName'."
        exit 1
    }
    
    # Show most recent commit
    $lastCommit = git -C $treePath log -1 --format="%s"
    Show-Info "Latest: $gray$lastCommit$reset"
}

# Find runnable projects
$runnableProjects = Find-RunnableProjects -TreePath $treePath
if ($runnableProjects.Count -eq 0)
{
    Write-Host ""
    ErrorOut "No runnable projects found in '$Repo/$treeName'."
    Write-Host "  ${gray}Looking for Web SDK or Console App projects$reset"
    Write-Host ""
    exit 1
}

# Select project
if ($SelectProject)
{
    # -p flag: show fzf picker
    $selectedProjectName = $runnableProjects | 
        ForEach-Object { $_.BaseName } | 
        fzf --height=50%
    
    if ([string]::IsNullOrWhiteSpace($selectedProjectName))
    {
        # User cancelled fzf
        exit 0
    }
    
    $selectedProject = $runnableProjects | Where-Object { $_.BaseName -eq $selectedProjectName }
}
elseif ([string]::IsNullOrWhiteSpace($Project))
{
    # Not provided: prefer first Web SDK project, fallback to first runnable
    $selectedProject = $runnableProjects | Where-Object { 
        (Get-Content $_.FullName -Raw) -match 'Microsoft\.NET\.Sdk\.Web' 
    } | Select-Object -First 1
    
    if ($null -eq $selectedProject)
    {
        $selectedProject = $runnableProjects | Select-Object -First 1
    }
}
else
{
    # Positional value provided: use specified project
    $selectedProject = $runnableProjects | Where-Object { $_.BaseName -eq $Project }
    
    if ($null -eq $selectedProject)
    {
        Write-Host ""
        ErrorOut "Project '$Project' not found in '$Repo/$treeName'."
        Write-Host ""
        Write-Host "  ${gray}Available projects:$reset"
        foreach ($proj in $runnableProjects)
        {
            Write-Host "    $cyan>$reset $($proj.BaseName)"
        }
        Write-Host ""
        exit 1
    }
}

# Run the project
$projectName = $selectedProject.BaseName

Write-Host ""
Show-Info "Repository: $gray$Repo$reset"
Show-Info "Worktree:   $gray$treeName$reset"
Show-Info "Project:    $gray$projectName$reset"
Write-Host ""

if ($VerboseOutput)
{
    Show-Success "Starting $cyan$projectName$reset..."
    Write-Host ""
    dotnet run --project $selectedProject.FullName
    exit $LASTEXITCODE
}

# Quiet mode: show spinner during build, then pass through output once running
$frameIndex = 0
$building = $true
$buildFailed = $false
$errorLines = @()
$outputBuffer = @()

# Set up the process
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "dotnet"
$psi.Arguments = "run --project `"$($selectedProject.FullName)`""
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi

# Set up async output reading
$outputBuilder = New-Object System.Text.StringBuilder
$errorBuilder = New-Object System.Text.StringBuilder

$outputHandler = {
    if (-not [String]::IsNullOrEmpty($EventArgs.Data))
    {
        $Event.MessageData.AppendLine($EventArgs.Data)
    }
}

$outputEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outputHandler -MessageData $outputBuilder
$errorEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $outputHandler -MessageData $errorBuilder

# Handle Ctrl+C to stop the child process
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    if ($process -and -not $process.HasExited)
    {
        $process.Kill()
    }
}

try
{
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    # Spinner loop
    Write-Host "  $($spinnerFrames[$frameIndex]) ${gray}Building...$reset" -NoNewline

    while (-not $process.HasExited)
    {
        Start-Sleep -Milliseconds 80
        
        # Update spinner
        if ($building)
        {
            $frameIndex = ($frameIndex + 1) % $spinnerFrames.Count
            Write-Host "`r  $($spinnerFrames[$frameIndex]) ${gray}Building...$reset" -NoNewline
        }
        
        # Check for output
        $currentOutput = $outputBuilder.ToString()
        $currentError = $errorBuilder.ToString()
        
        # Check for errors
        if ($currentOutput -match 'error CS' -or $currentOutput -match 'Build FAILED' -or 
            $currentError -match 'error CS' -or $currentError -match 'Build FAILED')
        {
            $buildFailed = $true
        }
        
        # Check if app is now running (build succeeded)
        if ($building -and ($currentOutput -match 'Now listening on:' -or 
                            $currentOutput -match 'Content root path:' -or
                            $currentOutput -match 'Application started'))
        {
            $building = $false
            Write-Host "`r  $green✓$reset Starting $cyan$projectName$reset...    "
            Write-Host ""
            
            # Output the buffered content that indicates the app is running
            $lines = $currentOutput -split "`r?`n"
            foreach ($line in $lines)
            {
                if ($line -match 'Now listening on:' -or 
                    $line -match 'Content root path:' -or 
                    $line -match 'Application started' -or
                    $line -match 'Hosting environment:' -or
                    $line -match 'https?://')
                {
                    Write-Host "  $cyan▶$reset $($line.Trim())"
                }
            }
            
            # Clear the builder so we don't re-process
            $outputBuilder.Clear() | Out-Null
        }
    }

    # Wait for async reads to complete
    $process.WaitForExit()

    # Get any remaining output
    $remainingOutput = $outputBuilder.ToString()
    $remainingError = $errorBuilder.ToString()

    if ($buildFailed -or $process.ExitCode -ne 0)
    {
        Write-Host "`r  $red✗$reset ${red}Build failed$reset              "
        Write-Host ""
        
        # Show error lines
        $allOutput = $remainingOutput + "`n" + $remainingError
        $lines = $allOutput -split "`r?`n"
        foreach ($line in $lines)
        {
            if ($line -match 'error CS' -or $line -match 'Build FAILED')
            {
                Write-Host $line
            }
        }
    }
    elseif ($building)
    {
        # Process exited but we never detected "running" state - might be a console app
        Write-Host "`r  $green✓$reset Starting $cyan$projectName$reset...    "
        Write-Host ""
        
        if ($remainingOutput)
        {
            Write-Host $remainingOutput
        }
    }

    $exitCode = $process.ExitCode
}
finally
{
    # Clean up: stop the process if still running
    if ($process -and -not $process.HasExited)
    {
        $process.Kill()
        $process.WaitForExit()
    }
    
    # Unregister events
    if ($outputEvent) { Unregister-Event -SourceIdentifier $outputEvent.Name -ErrorAction SilentlyContinue }
    if ($errorEvent) { Unregister-Event -SourceIdentifier $errorEvent.Name -ErrorAction SilentlyContinue }
    
    # Dispose process
    if ($process) { $process.Dispose() }
}

exit $exitCode
