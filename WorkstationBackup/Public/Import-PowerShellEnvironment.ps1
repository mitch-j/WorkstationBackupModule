<#
.SYNOPSIS
    Restores the PowerShell environment from a backup repository.

.DESCRIPTION
    Restores a workstation's PowerShell configuration from a backup repository,
    including profiles, settings files, Oh My Posh themes, Windows Terminal settings,
    and PowerShell Gallery modules.

.PARAMETER RepoRoot
    The root directory of the backup repository. If not provided, automatically
    determined from the module's location. Supports $env: variable expansion.

.PARAMETER ConfigPath
    Path to the powershell-sync.config.json configuration file. If not provided,
    defaults to $RepoRoot/powershell-sync.config.json.

.PARAMETER SkipFontInstallFailures
    If specified, continues restoration even if Nerd Font installation fails.
    Without this switch, font installation errors halt the process.

.EXAMPLE
    Import-PowerShellEnvironment

    Restores the environment from default locations using modular functions.

.EXAMPLE
    Import-PowerShellEnvironment -WhatIf

    Shows what would be restored without making changes.

.EXAMPLE
    Import-PowerShellEnvironment -RepoRoot 'C:\Backup\MyEnvironment'

    Restores from a custom repository location.

.EXAMPLE
    Import-PowerShellEnvironment -SkipFontInstallFailures

    Restores environment but continues even if font installation fails.

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
        [switch]$SkipFontInstallFailures
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $RepoRoot) {
        $RepoRoot = Get-WorkstationBackupRoot
    }

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $RepoRoot 'powershell-sync.config.json'
    }

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "Config file not found: $ConfigPath"
    }

    $config = Read-PowerShellSyncConfig -Path $ConfigPath
    Write-BackupLog -Message "Loaded config from $ConfigPath"

    if ($PSCmdlet.ShouldProcess("User environment variable PS_CONFIG_ROOT", "Set value to '$($config.RepoRoot)'")) {
        Set-BackupUserEnvironmentVariable -Name 'PS_CONFIG_ROOT' -Value $config.RepoRoot
    }

    if ($PSCmdlet.ShouldProcess("PowerShell environment", "Import from backup repository")) {
        Invoke-ApplyPowerShellEnvironment `
            -Config $config `
            -SkipFontInstallFailures:$SkipFontInstallFailures `
            -WhatIf:$WhatIfPreference
    }
}