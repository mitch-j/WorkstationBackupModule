function Export-PowerShellEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$LegacyScriptPath,

        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [string]$InternalModulesSourceRoot,

        [Parameter()]
        [string]$InternalModulesBackupRoot,

        [Parameter()]
        [string[]]$ExcludeInternalModules = @(),

        [Parameter()]
        [switch]$WriteInternalModuleManifest
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $RepoRoot) {
        $RepoRoot = Get-WorkstationBackupRoot
    }

    if (-not $LegacyScriptPath) {
        $LegacyScriptPath = Join-Path $RepoRoot 'Scripts\Legacy\Sync-PowerShellEnvironment.ps1'
    }

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $RepoRoot 'powershell-sync.config.json'
    }

    if (-not (Test-Path -LiteralPath $LegacyScriptPath)) {
        throw "Legacy export script not found: $LegacyScriptPath"
    }

    Write-BackupLog -Message "Running legacy PowerShell environment export via '$LegacyScriptPath'"

    $legacyArguments = @(
        '-NoProfile'
        '-ExecutionPolicy', 'Bypass'
        '-File', $LegacyScriptPath
        '-Mode', 'Export'
        '-ConfigPath', $ConfigPath
        '-SkipGit'
    )

    if ($WhatIfPreference) {
        $legacyArguments += '-WhatIf'
    }

    & pwsh.exe @legacyArguments

    if ($LASTEXITCODE -ne 0) {
        throw "Legacy PowerShell export failed with exit code $LASTEXITCODE."
    }

    if ($InternalModulesSourceRoot -and $InternalModulesBackupRoot) {
        Write-BackupLog -Message "Backing up internal modules from '$InternalModulesSourceRoot' to '$InternalModulesBackupRoot'"

        Export-InternalModuleBackup `
            -SourceRoot $InternalModulesSourceRoot `
            -DestinationRoot $InternalModulesBackupRoot `
            -ExcludeModules $ExcludeInternalModules `
            -WriteManifest:$WriteInternalModuleManifest `
            -WhatIf:$WhatIfPreference
    }
    else {
        Write-BackupLog -Message 'Internal module backup skipped because source or destination path was not provided.' -Level 'WARN'
    }
}