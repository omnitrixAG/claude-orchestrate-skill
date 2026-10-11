[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('codex', 'opencode')][string]$Backend,
    [string]$Model,
    [Parameter(Mandatory = $true)][string]$Worktree,
    [Parameter(Mandatory = $true)][string]$Pack,
    [Parameter(Mandatory = $true)][string]$Out,
    [ValidateRange(1, 1440)][int]$TimeoutMin = 20,
    [string]$TestCmd,
    [switch]$DryRun,
    [string[]]$AllowPaths = @(),
    [Alias('ForbidFile')][string[]]$ForbidPattern = @(),
    [string]$LaneId
)

$ErrorActionPreference = 'Stop'
$script:RunnerRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ResultPath = $null
$script:RunTimer = [Diagnostics.Stopwatch]::StartNew()
$script:StartingCommit = ''
$script:SelectedModel = ''
$script:LaneIdentifier = ''

function Fail-Usage([string]$Message) {
    [Console]::Error.WriteLine("dispatch.ps1: $Message")
    exit 2
}

function Normalize-Path([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { Fail-Usage "Path must be absolute: $Path" }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Is-UnderPath([string]$Child, [string]$Parent) {
    $c = (Normalize-Path $Child).ToLowerInvariant()
    $p = (Normalize-Path $Parent).ToLowerInvariant()
    return $c -eq $p -or $c.StartsWith($p + '\')
}

function Invoke-Git([string[]]$Arguments) {
    $output = & git -C $script:Worktree @Arguments 2>&1
    $code = $LASTEXITCODE
    [pscustomobject]@{ Output = @($output); ExitCode = $code }
}

function Expand-AllowPaths([string[]]$Values) {
    $expanded = [Collections.Generic.List[string]]::new()
    foreach ($value in $Values) {
        foreach ($part in ([string]$value -split '[,;]')) {
            $clean = $part.Trim().Trim('"').Trim("'").Replace('\', '/')
            if ($clean) { $expanded.Add($clean) }
        }
    }
    @($expanded | Sort-Object -Unique)
}

function Get-ConfiguredLaneModel {
    if ($Model) { return $Model }
    if ($Backend -eq 'opencode') { return 'backend-default' }
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    $laneConfig = Join-Path $userProfile '.codex\lane.config.toml'
    if (Test-Path -LiteralPath $laneConfig -PathType Leaf) {
        $match = [regex]::Match([IO.File]::ReadAllText($laneConfig), '(?m)^\s*model\s*=\s*"([^"]+)"\s*$')
        if ($match.Success) { return $match.Groups[1].Value }
    }
    return 'profile:lane'
}

function Quote-ProcessArgument([string]$Argument) {
    if ($Argument -notmatch '[\s"]') { return $Argument }
    return '"' + $Argument.Replace('"', '\"') + '"'
}

function Invoke-ProcessCapture([string]$FileName, [string[]]$Arguments, [int]$TimeoutSeconds, [string]$StdoutPath, [string]$StderrPath, [string]$StdinText = '', [string]$WorkingDirectory = '') {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.UseShellExecute = $false
    if ($WorkingDirectory) { $psi.WorkingDirectory = $WorkingDirectory }
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $quoted = ($Arguments | ForEach-Object { Quote-ProcessArgument ([string]$_) }) -join ' '
    if ($FileName -match '(?i)\.(cmd|bat)$') {
        $psi.FileName = $env:ComSpec
        $psi.Arguments = '/d /s /c ""' + $FileName + '" ' + $quoted + '"'
    } elseif ($FileName -match '(?i)\.ps1$') {
        $psi.FileName = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File ' + (Quote-ProcessArgument $FileName) + ' ' + $quoted
    } else {
        $psi.FileName = $FileName
        $psi.Arguments = $quoted
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    try {
        if (-not $process.Start()) { throw "Unable to start $FileName" }
        if ($StdinText) { $process.StandardInput.Write($StdinText) }
        $process.StandardInput.Close()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            try { $process.Kill() } catch { }
            $process.WaitForExit()
        }
        [IO.File]::WriteAllText($StdoutPath, $stdoutTask.Result, [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText($StderrPath, $stderrTask.Result, [Text.UTF8Encoding]::new($false))
        [pscustomobject]@{ ExitCode = if ($timedOut) { $null } else { $process.ExitCode }; TimedOut = $timedOut }
    } finally { $process.Dispose() }
}

function Get-ChangedFiles {
    $trackedResult = Invoke-Git @('diff', '--name-only')
    $untrackedResult = Invoke-Git @('ls-files', '--others', '--exclude-standard')
    $tracked = @($trackedResult.Output | Where-Object { $_ -and ([string]$_) -notmatch '^warning:' })
    $untracked = @($untrackedResult.Output | Where-Object { $_ -and ([string]$_) -notmatch '^warning:' })
    @($tracked + $untracked | ForEach-Object { ([string]$_).Replace('\', '/') } | Sort-Object -Unique)
}

function Get-DiffStats {
    $numstatResult = Invoke-Git @('diff', '--numstat')
    $numstat = @($numstatResult.Output | Where-Object { $_ -and ([string]$_) -match '^\d+\s+\d+\s+' })
    $insertions = 0
    $deletions = 0
    foreach ($line in $numstat) {
        $parts = ([string]$line) -split '\s+'
        $insertions += [int]$parts[0]
        $deletions += [int]$parts[1]
    }
    $untrackedResult = Invoke-Git @('ls-files', '--others', '--exclude-standard')
    $untracked = @($untrackedResult.Output | Where-Object { $_ -and ([string]$_) -notmatch '^warning:' })
    foreach ($file in $untracked) {
        $fullPath = Join-Path $script:Worktree ([string]$file)
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $insertions += @([IO.File]::ReadLines($fullPath)).Count
        }
    }
    $changed = @(Get-ChangedFiles)
    [pscustomobject]@{ files = $changed.Count; insertions = $insertions; deletions = $deletions; untracked = $untracked.Count }
}

function Write-Result([string]$Status, [string[]]$ChangedFiles, $DiffStats, [string]$TestCommand, $TestExitCode, [string]$TestResult, [string]$ScopeResult, [string[]]$Errors, [string[]]$Limitations) {
    $script:RunTimer.Stop()
    $result = [ordered]@{
        status = $Status
        backend = $Backend
        model = $script:SelectedModel
        starting_commit = $script:StartingCommit
        lane_id = $script:LaneIdentifier
        wall_time_seconds = [Math]::Round($script:RunTimer.Elapsed.TotalSeconds, 3)
        changed_files = @($ChangedFiles)
        diff_stats = $DiffStats
        test_command = $TestCommand
        test_exit_code = $TestExitCode
        test_result = $TestResult
        scope_result = $ScopeResult
        errors = @($Errors)
        limitations = @($Limitations)
    }
    [IO.File]::WriteAllText($script:ResultPath, ($result | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
}

$script:Worktree = Normalize-Path $Worktree
$packPath = Normalize-Path $Pack
$outPath = Normalize-Path $Out
if (-not (Test-Path -LiteralPath $script:Worktree -PathType Container)) { Fail-Usage "Worktree does not exist: $script:Worktree" }
if (-not (Test-Path -LiteralPath $packPath -PathType Leaf)) { Fail-Usage "Lane pack does not exist: $packPath" }
if (Is-UnderPath $outPath $script:Worktree) { Fail-Usage "Output directory must be outside the worktree: $outPath" }
New-Item -ItemType Directory -Force -Path $outPath | Out-Null
$script:ResultPath = Join-Path $outPath 'result.json'
$stdoutPath = Join-Path $outPath 'backend.stdout.log'
$stderrPath = Join-Path $outPath 'backend.stderr.log'
$testOutPath = Join-Path $outPath 'test.stdout.log'
$testErrPath = Join-Path $outPath 'test.stderr.log'
$packText = Get-Content -Raw -LiteralPath $packPath
$script:SelectedModel = Get-ConfiguredLaneModel
$script:LaneIdentifier = if ($LaneId) { $LaneId } else { [IO.Path]::GetFileNameWithoutExtension($packPath) }
if ($script:LaneIdentifier -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { Fail-Usage 'LaneId must contain only letters, numbers, dot, underscore, or hyphen.' }
$allowedPathPatterns = @(Expand-AllowPaths $AllowPaths)

$commitResult = Invoke-Git @('rev-parse', 'HEAD')
if ($commitResult.ExitCode -ne 0) { Fail-Usage 'Worktree is not a readable Git worktree.' }
$script:StartingCommit = [string](@($commitResult.Output) | Select-Object -First 1)
$branchResult = Invoke-Git @('branch', '--show-current')
$branch = [string](@($branchResult.Output) | Select-Object -First 1)
if ($branch -in @('main', 'master', 'ios-main', 'mac-main')) {
    Write-Result 'scope_violation' @() ([pscustomobject]@{files=0;insertions=0;deletions=0;untracked=0}) $TestCmd $null 'skipped' 'violated' @("Protected branch rejected: $branch") @()
    exit 3
}
$statusResult = Invoke-Git @('status', '--porcelain')
$initialStatus = @($statusResult.Output | Where-Object { $_ -and ([string]$_) -notmatch '^warning:' })
if ($initialStatus.Count -gt 0) {
    Write-Result 'scope_violation' @() ([pscustomobject]@{files=0;insertions=0;deletions=0;untracked=0}) $TestCmd $null 'skipped' 'violated' @('Worktree must be clean before dispatch.') @('Initial status: ' + ($initialStatus -join ' | '))
    exit 3
}

$limitations = [Collections.Generic.List[string]]::new()
$errors = [Collections.Generic.List[string]]::new()
if ($DryRun) {
    $limitations.Add('Dry-run: backend was not launched and tests were not run.')
    Write-Result 'ok' @() ([pscustomobject]@{files=0;insertions=0;deletions=0;untracked=0}) $TestCmd $null 'skipped' 'not_evaluated' @() $limitations
    exit 0
}
if ([string]::IsNullOrWhiteSpace($TestCmd)) { Fail-Usage 'TestCmd is required unless -DryRun is specified.' }
if ($TestCmd -match '(?i)(git\s+(reset|clean|push|merge)|remove-item|\bdel\b|\brm\b|format-volume|shutdown|stop-computer)') { Fail-Usage 'TestCmd contains a prohibited destructive or production-impacting command.' }
$backendCommand = if ($Backend -eq 'codex') { (Get-Command codex -ErrorAction Stop).Source } else { (Get-Command opencode -ErrorAction Stop).Source }
$backendPrefix = @()
if ($Backend -eq 'codex') {
    $nodeCommand = (Get-Command node.exe -ErrorAction Stop).Source
    $backendCommand = $nodeCommand
    $backendPrefix = @(Join-Path (Split-Path (Get-Command codex -ErrorAction Stop).Source -Parent) 'node_modules\@openai\codex\bin\codex.js')
    $agentArgs = @('--profile', 'lane', '--sandbox', 'workspace-write', 'exec', '--ephemeral', '-C', $script:Worktree, '--json', '--output-schema', (Join-Path $script:RunnerRoot 'lane-report.schema.json'), '-o', (Join-Path $outPath 'agent-final.json'))
    if ($Model) { $agentArgs += @('-m', $Model) }
    $agentArgs += '-'
    $agentStdin = $packText
} else {
    if ($backendCommand -match '(?i)\.ps1$') { $backendCommand = Join-Path (Split-Path $backendCommand -Parent) 'node_modules\opencode-ai\bin\opencode.exe' }
    $agentArgs = @('run', '--format', 'json', '--dir', $script:Worktree, '-f', $packPath)
    if ($Model) { $agentArgs += @('--model', $Model) }
    $agentArgs += 'Execute the attached lane pack exactly as written.'
    $agentStdin = ''
}
$agentArgs = @($backendPrefix) + @($agentArgs)
$agentRun = Invoke-ProcessCapture $backendCommand $agentArgs ($TimeoutMin * 60) $stdoutPath $stderrPath $agentStdin $script:Worktree
if ($agentRun.TimedOut) { $errors.Add('Backend timed out.') }
elseif ($agentRun.ExitCode -ne 0) { $errors.Add("Backend exited with code $($agentRun.ExitCode).") }

$changed = @(Get-ChangedFiles)
$diffStats = Get-DiffStats
$scopeResult = 'respected'
if ($allowedPathPatterns.Count -gt 0) {
    foreach ($file in $changed) {
        $allowed = $false
        foreach ($pattern in $allowedPathPatterns) {
            if ($file -like $pattern) { $allowed = $true; break }
        }
        if (-not $allowed) {
            $errors.Add("Out-of-scope changed path: $file")
            $scopeResult = 'violated'
        }
    }
}
$diffResult = Invoke-Git @('diff', '--unified=0')
$addedText = @($diffResult.Output) -join "`n"
foreach ($file in $changed) {
    $untrackedCheck = Invoke-Git @('ls-files', '--others', '--exclude-standard', '--', $file)
    if (@($untrackedCheck.Output).Count -gt 0) { $addedText += "`n" + (Get-Content -Raw -LiteralPath (Join-Path $script:Worktree $file)) }
}
foreach ($pattern in $ForbidPattern) {
    if ($addedText -match $pattern) { $errors.Add("Forbidden added-line pattern matched: $pattern") }
}

$testExit = $null
$testResult = 'skipped'
if ($errors.Count -eq 0 -and $TestCmd) {
    $testArgs = @('-NoProfile', '-Command', $TestCmd)
    $testRun = Invoke-ProcessCapture (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') $testArgs ($TimeoutMin * 60) $testOutPath $testErrPath '' $script:Worktree
    if ($testRun.TimedOut) {
        $testResult = 'timeout'
        $errors.Add('Independent test command timed out.')
    } else {
        $testExit = $testRun.ExitCode
        if ($testExit -eq 0) { $testResult = 'passed' }
        else {
            $testResult = 'failed'
            $errors.Add("Independent test command exited with code $testExit.")
        }
    }
}
$status = if ($agentRun.TimedOut) { 'timeout' } elseif (@($errors | Where-Object { $_ -like 'Out-of-scope*' }).Count -gt 0) { 'scope_violation' } elseif (@($errors | Where-Object { $_ -like 'Forbidden*' }).Count -gt 0) { 'forbidden_hit' } elseif ($agentRun.ExitCode -ne 0) { 'backend_failed' } elseif ($testResult -eq 'timeout') { 'timeout' } elseif ($testExit -ne 0) { 'tests_failed' } else { 'ok' }
Write-Result $status $changed $diffStats $TestCmd $testExit $testResult $scopeResult $errors $limitations
if ($status -eq 'ok') { exit 0 } else { exit 1 }
