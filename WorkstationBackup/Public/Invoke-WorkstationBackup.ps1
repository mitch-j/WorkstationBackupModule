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
        [string[]]$ChocoBackupArguments = @(),

        [Parameter()]
        [string]$InternalModulesSourceRoot,

        [Parameter()]
        [string]$InternalModulesBackupRoot,

        [Parameter()]
        [string[]]$ExcludeInternalModules = @(),

        [Parameter()]
        [switch]$WriteInternalModuleManifest
    )

    $RepoRoot = Get-WorkstationBackupRoot -RepoRoot $RepoRoot -ModuleRoot $PSScriptRoot
    $completedStages = [System.Collections.Generic.List[string]]::new()

    if (-not $SkipPowerShellBackup) {
        $exportParameters = @{
            RepoRoot = $RepoRoot
            SkipGit  = $true
        }
        if ($ConfigPath) { $exportParameters.ConfigPath = $ConfigPath }
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

        for ($i = 0; $i -lt $ChocoBackupArguments.Count; $i++) {
            $argument = $ChocoBackupArguments[$i]
            switch -Regex ($argument) {
                '^-IncludeVersions$' { $chocoParameters.IncludeVersions = $true; continue }
                '^-AllowOverwriteToday$' { $chocoParameters.AllowOverwriteToday = $true; continue }
                '^-RetentionCount$' {
                    if ($i + 1 -ge $ChocoBackupArguments.Count) {
                        throw 'ChocoBackupArguments included -RetentionCount without a value.'
                    }
                    $i++
                    $chocoParameters.RetentionCount = [int]$ChocoBackupArguments[$i]
                    continue
                }
                default {
                    throw "Unsupported ChocoBackupArguments value '$argument' in the module refactor. Add explicit parameter support here instead of passing through arbitrary strings."
                }
            }
        }

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

    if (-not $SkipGit) {
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
        GitEnabled      = (-not $SkipGit)
        CommitMessage   = $CommitMessage
    }
}
