<#
.SYNOPSIS
    Orchestrates a full workstation backup with optional Git synchronization.

.DESCRIPTION
    Runs PowerShell environment export, Chocolatey export, and optional Git sync in a
    single command. The command uses the JSON configuration file as the primary source
    of path and repository information when `-ConfigPath` is supplied.

.PARAMETER RepoRoot
    The root directory of the backup repository. If omitted, it is resolved from the
    module root or the configuration file when `-ConfigPath` is provided.

.PARAMETER ConfigPath
    Path to the powershell-sync.config.json file. When supplied without `-RepoRoot`, the
    repository root is derived from the configuration file.

.PARAMETER SkipPowerShellBackup
    Skip the PowerShell environment export stage.

.PARAMETER SkipChocoBackup
    Skip the Chocolatey package export stage.

.PARAMETER SkipGit
    Skip Git commit/push/pull synchronization.

.PARAMETER SkipPull
    Skip git pull before pushing changes.

.PARAMETER SkipPush
    Skip git push after committing changes.

.PARAMETER CommitMessage
    Custom commit message for the Git sync stage.

.PARAMETER AllowOverwriteToday
    Allow Chocolatey export to overwrite today's manifest if it already exists.

.PARAMETER IncludeVersions
    Include package version information in the Chocolatey export manifest.

.PARAMETER RetentionCount
    Number of Chocolatey export manifests to retain. Older exports are automatically removed.

.PARAMETER InternalModulesSourceRoot
    Source directory for custom internal PowerShell modules.

.PARAMETER InternalModulesBackupRoot
    Destination directory inside the backup repo for internal modules.

.PARAMETER ExcludeInternalModules
    List of module names to exclude from internal module backup.

.PARAMETER WriteInternalModuleManifest
    If specified, writes a manifest JSON file listing backed up internal modules.

.EXAMPLE
    Invoke-WorkstationBackup

    Runs all backup stages and synchronizes changes to Git using the default repo root.

.EXAMPLE
    Invoke-WorkstationBackup -ConfigPath 'C:\Dev\work\backup-repo\powershell-sync.config.json'

    Uses an external config file and backup repository.

.EXAMPLE
    Invoke-WorkstationBackup -SkipChocoBackup -WhatIf

    Previews a PowerShell-only backup without Chocolatey export.

.NOTES
    - This command is the preferred entrypoint for full workstation backup workflows.
    - `Export-PowerShellEnvironment` does not perform Git synchronization itself; Git sync is handled by this wrapper.
    - If no backup stages are selected, the command logs a warning and exits.

.INPUTS
    None.

.OUTPUTS
    PSCustomObject
#>
function Invoke-WorkstationBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot = 'C:\Dev\work\WorkstationBackup',

        [Parameter()]
        [string]$ConfigPath,

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
        [string]$CommitMessage,

        [Parameter()]
        [switch]$AllowOverwriteToday,

        [Parameter()]
        [switch]$IncludeVersions,

        [Parameter()]
        [int]$RetentionCount = 0,

        [Parameter()]
        [string]$InternalModulesSourceRoot,

        [Parameter()]
        [string]$InternalModulesBackupRoot,

        [Parameter()]
        [string[]]$ExcludeInternalModules = @(),

        [Parameter()]
        [switch]$WriteInternalModuleManifest
    )

    if ($ConfigPath -and -not $RepoRoot) {
        if (-not (Test-Path -LiteralPath $ConfigPath)) {
            throw "Config file not found: $ConfigPath"
        }

        $config = Read-PowerShellSyncConfig -Path $ConfigPath
        $RepoRoot = $config.RepoRoot
    }

    $RepoRoot = Get-WorkstationBackupRoot -RepoRoot $RepoRoot -ModuleRoot $PSScriptRoot
    $completedStages = [System.Collections.Generic.List[string]]::new()

    if (-not $SkipPowerShellBackup) {
        $exportParameters = @{
            RepoRoot = $RepoRoot
        }
        if ($ConfigPath) { $exportParameters.ConfigPath = $ConfigPath }
        if ($InternalModulesSourceRoot) { $exportParameters.InternalModulesSourceRoot = $InternalModulesSourceRoot }
        if ($InternalModulesBackupRoot) { $exportParameters.InternalModulesBackupRoot = $InternalModulesBackupRoot }
        if ($ExcludeInternalModules.Count -gt 0) { $exportParameters.ExcludeInternalModules = $ExcludeInternalModules }
        if ($WriteInternalModuleManifest) { $exportParameters.WriteInternalModuleManifest = $true }
        if ($WhatIfPreference) { $exportParameters.WhatIf = $true }

        if ($PSCmdlet.ShouldProcess("PowerShell environment", "Export to backup repository")) {
            Export-PowerShellEnvironment @exportParameters
        }
        $completedStages.Add('PowerShell')
    }

    if (-not $SkipChocoBackup) {
        $chocoParameters = @{
            RepoRoot = $RepoRoot
        }

        if ($AllowOverwriteToday) { $chocoParameters.AllowOverwriteToday = $true }
        if ($IncludeVersions) { $chocoParameters.IncludeVersions = $true }
        if ($RetentionCount -gt 0) { $chocoParameters.RetentionCount = $RetentionCount }

        if ($WhatIfPreference) { $chocoParameters.WhatIf = $true }
        if ($PSCmdlet.ShouldProcess("Chocolatey packages", "Export to backup repository")) {
            Export-ChocoMachineBackup @chocoParameters
        }
        $completedStages.Add('Chocolatey')
    }

    if ($completedStages.Count -eq 0) {
        Write-BackupLog 'No backup stages were selected. Nothing to do.' 'WARN'
        return
    }

    $gitRepoDetected = $false
    if (-not $SkipGit) {
        $gitDotGitPath = Join-Path $RepoRoot '.git'
        if (Test-Path -LiteralPath $gitDotGitPath) {
            $gitRepoDetected = $true
        }
        else {
            Write-BackupLog "Skipping Git sync because '$RepoRoot' is not a Git repository." 'WARN'
        }
    }

    if (-not $SkipGit -and $gitRepoDetected) {
        if (-not $CommitMessage) {
            $identity = Get-WorkstationIdentity
            $stageText = $completedStages -join ', '
            $CommitMessage = 'Workstation backup from {0} on {1} [{2}]' -f $identity.ComputerName, $identity.DateStamp, $stageText
        }

        if ($PSCmdlet.ShouldProcess("Git repository", "Sync backup changes")) {
            Invoke-BackupGitSync -RepoRoot $RepoRoot -CommitMessage $CommitMessage -SkipPull:$SkipPull -SkipPush:$SkipPush -WhatIf:$WhatIfPreference
        }
    }

    [pscustomobject]@{
        RepoRoot        = $RepoRoot
        CompletedStages = @($completedStages)
        GitEnabled      = (-not $SkipGit -and $gitRepoDetected)
        CommitMessage   = $CommitMessage
    }
}
