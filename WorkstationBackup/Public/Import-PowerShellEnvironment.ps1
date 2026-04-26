<#
.SYNOPSIS
    Restores the PowerShell environment from a backup repository.

.DESCRIPTION
    Restores a workstation's PowerShell configuration from a backup repository,
    including profiles, settings files, Oh My Posh themes, Windows Terminal settings,
    and PowerShell Gallery modules.

    By default, uses the new modular restore functions. Can fall back to the legacy
    script for features not yet migrated via the -UseLegacyScript switch.

.PARAMETER RepoRoot
    The root directory of the backup repository. If not provided, automatically
    determined from the module's location. Supports $env: variable expansion.

.PARAMETER ConfigPath
    Path to the powershell-sync.config.json configuration file. If not provided,
    defaults to $RepoRoot/powershell-sync.config.json.

.PARAMETER SkipFontInstallFailures
    If specified, continues restoration even if Nerd Font installation fails.
    Without this switch, font installation errors halt the process.

.PARAMETER UseLegacyScript
    If specified, uses the legacy Sync-PowerShellEnvironment.ps1 script instead
    of the new modular functions. Use this for features not yet migrated.

.EXAMPLE
    Import-PowerShellEnvironment

    Restores the environment from default locations using new modular functions.

.EXAMPLE
    Import-PowerShellEnvironment -WhatIf

    Shows what would be restored without making changes.

.EXAMPLE
    Import-PowerShellEnvironment -RepoRoot 'C:\Backup\MyEnvironment'

    Restores from a custom repository location.

.EXAMPLE
    Import-PowerShellEnvironment -SkipFontInstallFailures

    Restores environment but continues even if font installation fails.

.EXAMPLE
    Import-PowerShellEnvironment -UseLegacyScript

    Falls back to legacy script for advanced features (temporary compatibility).

.NOTES
    - Requires PowerShell 7.0 or later
    - Creates necessary directories before restoring files
    - All operations support WhatIf for safe preview
    - Font installations may require administrator privileges
    - PowerShell modules are installed to ExternalModulesPath from config

.INPUTS
    None. Pipeline input not supported.

.OUTPUTS
    None. Outputs messages to the console and logs.

.LINK
    Export-PowerShellEnvironment
    Invoke-WorkstationBackup
#>
function Import-PowerShellEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [switch]$SkipFontInstallFailures,

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
        $LegacyScriptPath = Join-Path $RepoRoot 'Scripts\Legacy\Sync-PowerShellEnvironment.ps1'
        if (-not (Test-Path -LiteralPath $LegacyScriptPath)) {
            throw "Legacy import script not found: $LegacyScriptPath"
        }

        Write-BackupLog -Message "Running legacy PowerShell environment import via '$LegacyScriptPath'" -Level 'WARN'

        $legacyArguments = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', $LegacyScriptPath
            '-Mode', 'Apply'
            '-ConfigPath', $ConfigPath
            '-SkipGit'
        )

        if ($SkipFontInstallFailures) {
            $legacyArguments += '-SkipFontInstallFailures'
        }

        if ($WhatIfPreference) {
            $legacyArguments += '-WhatIf'
        }

        & pwsh.exe @legacyArguments

        if ($LASTEXITCODE -ne 0) {
            throw "Legacy PowerShell import failed with exit code $LASTEXITCODE."
        }

        return
    }

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    $config = Read-PowerShellSyncConfig -Path $ConfigPath
    Write-BackupLog -Message "Loaded config from $ConfigPath"

    Set-BackupUserEnvironmentVariable -Name 'PS_CONFIG_ROOT' -Value $config.RepoRoot

    Invoke-ApplyPowerShellEnvironment `
        -Config $config `
        -SkipFontInstallFailures:$SkipFontInstallFailures `
        -WhatIf:$WhatIfPreference
}