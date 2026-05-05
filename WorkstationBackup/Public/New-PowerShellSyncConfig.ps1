<#
.SYNOPSIS
    Creates or updates the powershell-sync.config.json configuration file for a backup repository.

.DESCRIPTION
    Generates the JSON configuration file that defines backup paths, profile mappings,
    theme and terminal settings, font restore targets, and module directories.
    This command is the recommended first step when setting up a new backup repo or
    onboarding a new workstation.

.PARAMETER RepoRoot
    The root directory of the backup repository. If omitted, the module root is used as
    a starting point and the user is prompted to confirm the location.

.PARAMETER ConfigPath
    The path to write the configuration file. Defaults to '$RepoRoot\powershell-sync.config.json'.

.PARAMETER Force
    Overwrite an existing configuration file.

.PARAMETER UseDefaults
    Generate the config file without prompting for values.

.EXAMPLE
    New-PowerShellSyncConfig

    Generates a new config file in the current repository root.

.EXAMPLE
    New-PowerShellSyncConfig -RepoRoot 'C:\Dev\work\backup-repo'

    Creates the config file in a separate backup repository.

.EXAMPLE
    New-PowerShellSyncConfig -ConfigPath 'C:\Dev\work\backup-repo\powershell-sync.config.json' -Force

    Writes the config file to a custom location and overwrites any existing file.

.NOTES
    - Keep the config file under version control in your backup repository.
    - The generated config file uses template expansion for environment variables and profile paths.
    - Use this command before running Export-PowerShellEnvironment or Import-PowerShellEnvironment.

.INPUTS
    None.

.OUTPUTS
    PSCustomObject
#>
function New-PowerShellSyncConfig {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$UseDefaults
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if ($RepoRoot) {
        $RepoRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RepoRoot)
    }
    else {
        $RepoRoot = Get-WorkstationBackupRoot -ModuleRoot $PSScriptRoot
    }

    if (-not $UseDefaults) {
        $userRepoRoot = Read-Host "Backup repository root [$RepoRoot]"
        if (-not [string]::IsNullOrWhiteSpace($userRepoRoot)) {
            $RepoRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($userRepoRoot)
        }
    }

    if (-not $RepoRoot) {
        throw 'A backup repository root must be provided.'
    }

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $RepoRoot 'powershell-sync.config.json'
    }
    else {
        $ConfigPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigPath)
    }

    $configDirectory = Split-Path -Path $ConfigPath -Parent
    if (-not (Test-Path -LiteralPath $configDirectory)) {
        if ($PSCmdlet.ShouldProcess($configDirectory, 'Create config directory')) {
            New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
        }
    }

    if ((Test-Path -LiteralPath $ConfigPath) -and (-not $Force)) {
        if ($WhatIfPreference) {
            Write-BackupLog -Message "Config file already exists at '$ConfigPath' and would not be overwritten without -Force."
            return
        }

        throw "Config file already exists at '$ConfigPath'. Use -Force to overwrite."
    }

    $config = [pscustomobject]@{
        RepoRoot            = $RepoRoot
        ComputerName        = $null
        PersonalModulesPath = 'Modules\\Personal'
        ExternalModulesPath = 'Modules\\External'
        InventoryDirectory  = 'Config\\{ComputerName}'
        ProfilesDirectory   = 'Config\\{ComputerName}'
        SettingsDirectory   = 'Config\\{ComputerName}'
        ThemesDirectory     = 'Config\\{ComputerName}\\Themes'
        FontsDirectory      = 'Config\\{ComputerName}\\Fonts'
        LogDirectory        = 'Logs'
        PersonalModules     = @()
        Profiles            = @(
            [pscustomobject]@{ Source = '$PROFILE.CurrentUserCurrentHost'; Destination = 'Microsoft.PowerShell_profile.ps1' },
            [pscustomobject]@{ Source = '$PROFILE.CurrentUserAllHosts'; Destination = 'profile.ps1' }
        )
        SettingsFiles       = @()
        OhMyPosh            = [pscustomobject]@{
            BackupEnabled     = $true
            BackupAllThemes   = $true
            ThemeSourcePath   = '$env:POSH_THEMES_PATH'
            ThemeBackupPath   = 'Config\\{ComputerName}\\Themes'
            RestoreTargetPath = 'Config\\{ComputerName}\\Themes'
        }
        Fonts               = [pscustomobject]@{
            BackupEnabled           = $true
            InstallOnApply          = $true
            Provider                = 'NerdFonts'
            DiscoveryEnabled        = $true
            Scope                   = 'CurrentUser'
            RequiredFonts           = @()
            InventoryPath           = 'Config\\{ComputerName}\\fonts.json'
            AutoDetectFromInstalled = $true
            Files                   = @()
            RestoreDirectory        = '$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts'
        }
        WindowsTerminal     = [pscustomobject]@{
            BackupEnabled      = $true
            SettingsSourcePath = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
            SettingsBackupPath = 'Config\\{ComputerName}\\settings.json'
            RestoreTargetPath  = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
        }
    }

    if ($PSCmdlet.ShouldProcess($ConfigPath, 'Create configuration file')) {
        $config | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
        Write-BackupLog -Message "Created config file at $ConfigPath"
    }

    [pscustomobject]@{
        ConfigPath = $ConfigPath
        RepoRoot   = $RepoRoot
        Config     = $config
    }
}
