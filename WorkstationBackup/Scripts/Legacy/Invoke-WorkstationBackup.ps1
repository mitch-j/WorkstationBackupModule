<#
.SYNOPSIS
Runs workstation backup/export components and optionally performs a Git sync for the repository.

.DESCRIPTION
Invoke-WorkstationBackup.ps1 is an orchestration wrapper for recurring workstation
state capture.

It is intended to:
- run the PowerShell environment sync/export script
- run the Chocolatey package export script
- stage and commit resulting repository changes
- optionally push them to the remote repository

This script is a convenient scheduled entry point for workstation backup workflows.
It centralizes Git operations so component scripts can remain focused on their own
export and restore responsibilities.

.PARAMETER RepoRoot
Path to the repository root.

Default:
Parent of the directory containing this script.

.PARAMETER PowerShellSyncScriptPath
Path to the PowerShell environment sync/export script.

Default:
<RepoRoot>\Scripts\Sync-PowerShellEnvironment.ps1

.PARAMETER PowerShellSyncMode
Mode to use when invoking the PowerShell environment sync script.

Valid values:
- Sync
- Apply
- Export
- RegisterScheduledTask

Default:
Export

.PARAMETER ChocoBackupScriptPath
Path to the Chocolatey machine backup script.

Default:
<RepoRoot>\Scripts\Export-ChocoMachineBackup.ps1

.PARAMETER ChocoBackupArguments
Additional arguments to pass through to the Chocolatey backup script.

.PARAMETER SkipPowerShellBackup
Skips invocation of the PowerShell environment sync/export script.

.PARAMETER SkipChocoBackup
Skips invocation of the Chocolatey package export script.

.PARAMETER SkipGit
Skips all Git operations.

.PARAMETER SkipPull
Skips the initial git pull --rebase --autostash step.

Ignored when -SkipGit is specified.

.PARAMETER SkipPush
Skips git push after a successful commit.

Ignored when -SkipGit is specified.

.PARAMETER CommitMessage
Optional custom Git commit message.

If not supplied, the script generates a default message that includes the machine name,
date, and the completed backup stages.

.PARAMETER WhatIf
Shows what would happen without making changes where supported.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-WorkstationBackup.ps1

Runs the PowerShell environment export script, runs the Chocolatey backup script,
then stages, commits, and pushes repository changes.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-WorkstationBackup.ps1 -SkipChocoBackup

Runs only the PowerShell environment backup stage, then performs Git operations.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-WorkstationBackup.ps1 -SkipPowerShellBackup

Runs only the Chocolatey package backup stage, then performs Git operations.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-WorkstationBackup.ps1 -SkipGit

Runs component backup scripts without any Git pull, commit, or push activity.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-WorkstationBackup.ps1 -SkipPush -CommitMessage "Workstation backup snapshot"

Runs backup stages, commits changes with a custom message, and does not push.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-WorkstationBackup.ps1 -ChocoBackupArguments @('-IncludeVersions','-RetentionCount','10')

Invokes the Chocolatey backup script with additional arguments.

.NOTES
This script requires PowerShell 7 or later.

Git must be available in PATH unless -SkipGit is specified.
Child scripts must exist at the resolved paths or the script will stop with an error.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepoRoot,

    [Parameter()]
    [string]$PowerShellSyncScriptPath,

    [Parameter()]
    [ValidateSet('Sync','Apply','Export','RegisterScheduledTask')]
    [string]$PowerShellSyncMode = 'Export',

    [Parameter()]
    [string]$ChocoBackupScriptPath,

    [Parameter()]
    [string[]]$ChocoBackupArguments = @(),

    [Parameter()]
    [switch]$SkipPowerShellBackup,

    [Parameter()]
    [switch]$SkipChocoBackup,

    [Parameter()]
    [switch]$SkipGit,

    [Parameter()]
    [switch]$SkipPull,

    [Parameter()]
    [switch]$SkipPush,

    [Parameter()]
    [string]$CommitMessage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-WrapperLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message"
}

function Assert-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$CommandName' was not found in PATH."
    }
}

function Assert-FileExists {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description not found at '$Path'."
    }
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    Write-WrapperLog ("git " + ($Arguments -join ' '))

    if ($WhatIfPreference) {
        return
    }

    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
}

function Get-GitStatusPorcelain {
    if ($WhatIfPreference) {
        return ''
    }

    & git status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to query git status.'
    }
}

function Get-DefaultCommitMessage {
    param(
        [Parameter(Mandatory)]
        [string[]]$CompletedStages
    )

    $hostName = $env:COMPUTERNAME
    $dateStamp = Get-Date -Format 'yyyy-MM-dd'
    $stageText = ($CompletedStages -join ', ')
    return "Workstation backup from $hostName on $dateStamp [$stageText]"
}

function Invoke-ChildScript {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter()]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    Assert-FileExists -Path $ScriptPath -Description $DisplayName

    $displayArgs = if ($Arguments.Count -gt 0) { ' ' + ($Arguments -join ' ') } else { '' }
    Write-WrapperLog "Invoking $DisplayName: $ScriptPath$displayArgs"

    if ($WhatIfPreference) {
        return
    }

    & $ScriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$DisplayName failed with exit code $LASTEXITCODE."
    }
}

try {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "This script requires PowerShell 7 or higher. Run it with 'pwsh'."
    }

    $scriptDirectory = Split-Path -Path $PSCommandPath -Parent

    if (-not $RepoRoot) {
        $RepoRoot = Split-Path -Path $scriptDirectory -Parent
    }

    $RepoRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RepoRoot)

    if (-not $PowerShellSyncScriptPath) {
        $PowerShellSyncScriptPath = Join-Path $RepoRoot 'Scripts\Sync-PowerShellEnvironment.ps1'
    }

    if (-not $ChocoBackupScriptPath) {
        $ChocoBackupScriptPath = Join-Path $RepoRoot 'Scripts\Export-ChocoMachineBackup.ps1'
    }

    Write-WrapperLog "Using repository root $RepoRoot"

    if (-not (Test-Path -LiteralPath $RepoRoot)) {
        throw "Repository root '$RepoRoot' does not exist."
    }

    Assert-CommandExists -CommandName 'git'
    Push-Location $RepoRoot
    try {
        if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot '.git'))) {
            throw "Path '$RepoRoot' is not a Git repository."
        }

        $completedStages = New-Object System.Collections.Generic.List[string]

        if (-not $SkipGit -and -not $SkipPull) {
            if ($PSCmdlet.ShouldProcess($RepoRoot, 'git pull --rebase --autostash')) {
                Invoke-Git -Arguments @('pull','--rebase','--autostash')
            }
        }
        elseif (-not $SkipGit -and $SkipPull) {
            Write-WrapperLog 'Skipping git pull by request' 'WARN'
        }

        if (-not $SkipPowerShellBackup) {
            $psArgs = @('-Mode', $PowerShellSyncMode, '-SkipGit')
            if ($WhatIfPreference) {
                $psArgs += '-WhatIf'
            }

            if ($PSCmdlet.ShouldProcess($PowerShellSyncScriptPath, "Run PowerShell backup in mode $PowerShellSyncMode")) {
                Invoke-ChildScript -ScriptPath $PowerShellSyncScriptPath -Arguments $psArgs -DisplayName 'PowerShell environment backup script'
                [void]$completedStages.Add("PowerShell:$PowerShellSyncMode")
            }
        }
        else {
            Write-WrapperLog 'Skipping PowerShell backup by request' 'WARN'
        }

        if (-not $SkipChocoBackup) {
            $chocoArgs = @($ChocoBackupArguments)
            if ($WhatIfPreference -and ($chocoArgs -notcontains '-WhatIf')) {
                $chocoArgs += '-WhatIf'
            }

            if ($PSCmdlet.ShouldProcess($ChocoBackupScriptPath, 'Run Chocolatey machine backup')) {
                Invoke-ChildScript -ScriptPath $ChocoBackupScriptPath -Arguments $chocoArgs -DisplayName 'Chocolatey machine backup script'
                [void]$completedStages.Add('Chocolatey:Export')
            }
        }
        else {
            Write-WrapperLog 'Skipping Chocolatey backup by request' 'WARN'
        }

        if ($SkipGit) {
            Write-WrapperLog 'Skipping Git stage/commit/push by request' 'WARN'
            return
        }

        if ($PSCmdlet.ShouldProcess($RepoRoot, 'git add -A')) {
            Invoke-Git -Arguments @('add','-A')
        }

        $gitStatus = Get-GitStatusPorcelain
        if ([string]::IsNullOrWhiteSpace($gitStatus)) {
            Write-WrapperLog 'No Git changes detected after backup steps'
            return
        }

        if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
            $CommitMessage = Get-DefaultCommitMessage -CompletedStages @($completedStages)
        }

        if ($PSCmdlet.ShouldProcess($RepoRoot, "git commit with message '$CommitMessage'")) {
            Invoke-Git -Arguments @('commit','-m', $CommitMessage)
        }

        if (-not $SkipPush) {
            if ($PSCmdlet.ShouldProcess($RepoRoot, 'git push')) {
                Invoke-Git -Arguments @('push')
            }
        }
        else {
            Write-WrapperLog 'Skipping git push by request' 'WARN'
        }
    }
    finally {
        Pop-Location
    }
}
catch {
    Write-WrapperLog $_.Exception.Message 'ERROR'
    throw
}
