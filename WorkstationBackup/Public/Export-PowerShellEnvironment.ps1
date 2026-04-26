<#
.SYNOPSIS
    Exports the current PowerShell environment to a backup repository.

.DESCRIPTION
    Exports the current workstation's PowerShell configuration including profiles,
    settings files, Oh My Posh themes, Windows Terminal settings, and PowerShell
    Gallery modules to a backup repository for version control and restoration.

    By default, uses the new modular export functions. Can fall back to the legacy
    script for features not yet migrated via the -UseLegacyScript switch.

.PARAMETER RepoRoot
    The root directory of the backup repository. If not provided, automatically
    determined from the module's location. Supports $env: variable expansion.

.PARAMETER ConfigPath
    Path to the powershell-sync.config.json configuration file. If not provided,
    defaults to $RepoRoot/powershell-sync.config.json.

.PARAMETER InternalModulesSourceRoot
    Source directory for custom PowerShell modules to back up. When specified
    along with InternalModulesBackupRoot, internal modules are also exported.

.PARAMETER InternalModulesBackupRoot
    Destination directory in the repository for internal module backups.

.PARAMETER ExcludeInternalModules
    Array of module names to exclude from internal module backup.
    Example: @('Test-Module', 'Dev-Module')

.PARAMETER WriteInternalModuleManifest
    If specified, writes a manifest JSON file listing all backed up internal modules.

.PARAMETER UseLegacyScript
    If specified, uses the legacy Sync-PowerShellEnvironment.ps1 script instead
    of the new modular functions. Use this for features not yet migrated.

.EXAMPLE
    Export-PowerShellEnvironment

    Exports the current environment using the new modular functions with defaults.

.EXAMPLE
    Export-PowerShellEnvironment -WhatIf

    Shows what would be exported without making changes.

.EXAMPLE
    Export-PowerShellEnvironment -RepoRoot 'C:\Backup\MyEnvironment'

    Exports to a custom repository location.

.EXAMPLE
    Export-PowerShellEnvironment `
        -InternalModulesSourceRoot 'C:\Modules\MyModules' `
        -InternalModulesBackupRoot 'Modules\Internal' `
        -WriteInternalModuleManifest

    Exports environment and also backs up custom modules with a manifest.

.EXAMPLE
    Export-PowerShellEnvironment -UseLegacyScript

    Falls back to legacy script for advanced features (temporary compatibility).

.NOTES
    - Requires PowerShell 7.0 or later
    - Uses SHA256 hash comparison to avoid unnecessary file copies
    - All operations support WhatIf for safe preview
    - Logs all operations to the configured LogDirectory

.INPUTS
    None. Pipeline input not supported.

.OUTPUTS
    None. Outputs messages to the console and logs.

.LINK
    Import-PowerShellEnvironment
    Invoke-WorkstationBackup
#>
function Export-PowerShellEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [string]$InternalModulesSourceRoot,

        [Parameter()]
        [string]$InternalModulesBackupRoot,

        [Parameter()]
        [string[]]$ExcludeInternalModules = @(),

        [Parameter()]
        [switch]$WriteInternalModuleManifest,

        [Parameter()]
        [switch]$UseLegacyScript
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $RepoRoot) {
        $RepoRoot = Get-WorkstationBackupRoot
    }

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $RepoRoot 'powershell-sync.config.json'
    }

    if ($UseLegacyScript) {
        # Fallback to legacy script
        $LegacyScriptPath = Join-Path $RepoRoot 'Scripts\Legacy\Sync-PowerShellEnvironment.ps1'
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
    }
    else {
        # Use module functions
        if (-not (Test-Path -LiteralPath $ConfigPath)) {
            throw "Config file not found: $ConfigPath"
        }

        $config = Read-PowerShellSyncConfig -Path $ConfigPath
        Write-BackupLog -Message "Loaded config from $ConfigPath"

        # Initialize directories
        Initialize-ConfigDirectories -Config $config

        # Sync module paths
        Sync-PSModulePath -Config $config

        # Export PowerShell profiles
        Backup-PowerShellProfiles -Config $config

        # Export settings files
        Backup-SettingsFiles -Config $config

        # Export Oh My Posh themes
        Backup-OhMyPoshThemes -Config $config

        # Export Windows Terminal settings
        Backup-WindowsTerminal -Config $config

        # Export PowerShell Gallery modules
        Export-PowerShellModules -Config $config
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