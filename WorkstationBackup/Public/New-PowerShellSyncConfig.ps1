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
        PersonalModulesPath = 'Modules\\Personal'
        ExternalModulesPath = 'Modules\\External'
        InventoryDirectory  = 'Inventory'
        ProfilesDirectory   = 'Profiles'
        SettingsDirectory   = 'Settings'
        ThemesDirectory     = 'Themes'
        FontsDirectory      = 'Fonts'
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
            ThemeBackupPath   = 'Themes\\oh-my-posh'
            RestoreTargetPath = 'Themes\\oh-my-posh'
        }
        Fonts               = [pscustomobject]@{
            BackupEnabled           = $true
            InstallOnApply          = $true
            Provider                = 'NerdFonts'
            DiscoveryEnabled        = $true
            Scope                   = 'CurrentUser'
            RequiredFonts           = @()
            InventoryPath           = 'Inventory\\fonts.json'
            AutoDetectFromInstalled = $true
            Files                   = @()
            RestoreDirectory        = '$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts'
        }
        WindowsTerminal     = [pscustomobject]@{
            BackupEnabled      = $true
            SettingsSourcePath = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
            SettingsBackupPath = 'Settings\\windows-terminal\\settings.json'
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
