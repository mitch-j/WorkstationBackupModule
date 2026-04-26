function Read-PowerShellSyncConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $cfg = $raw | ConvertFrom-Json -Depth 50

    foreach ($required in 'RepoRoot','PersonalModulesPath','ExternalModulesPath','InventoryDirectory','ProfilesDirectory','SettingsDirectory','ThemesDirectory','FontsDirectory','LogDirectory','PersonalModules') {
        if (-not $cfg.PSObject.Properties.Name.Contains($required)) {
            throw "Missing required config property: $required"
        }
    }

    $repoRoot = Resolve-TemplateValue -Value $cfg.RepoRoot
    if (-not [System.IO.Path]::IsPathRooted($repoRoot)) {
        throw "RepoRoot must resolve to an absolute path. Current value: $($cfg.RepoRoot)"
    }

    $cfg.RepoRoot = $repoRoot
    $cfg.PersonalModulesPath = Resolve-TemplateValue -Value $cfg.PersonalModulesPath -RelativeRoot $cfg.RepoRoot
    $cfg.ExternalModulesPath = Resolve-TemplateValue -Value $cfg.ExternalModulesPath -RelativeRoot $cfg.RepoRoot
    $cfg.InventoryDirectory = Resolve-TemplateValue -Value $cfg.InventoryDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.ProfilesDirectory = Resolve-TemplateValue -Value $cfg.ProfilesDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.SettingsDirectory = Resolve-TemplateValue -Value $cfg.SettingsDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.ThemesDirectory = Resolve-TemplateValue -Value $cfg.ThemesDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.FontsDirectory = Resolve-TemplateValue -Value $cfg.FontsDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.LogDirectory = Resolve-TemplateValue -Value $cfg.LogDirectory -RelativeRoot $cfg.RepoRoot

    if (-not $cfg.PSObject.Properties.Name.Contains('DefaultRepository') -or [string]::IsNullOrWhiteSpace($cfg.DefaultRepository)) {
        $cfg | Add-Member -NotePropertyName DefaultRepository -NotePropertyValue 'PSGallery'
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('Profiles')) {
        $cfg | Add-Member -NotePropertyName Profiles -NotePropertyValue @(
            [pscustomobject]@{ Source = '$PROFILE.CurrentUserCurrentHost'; Destination = 'Microsoft.PowerShell_profile.ps1' },
            [pscustomobject]@{ Source = '$PROFILE.CurrentUserAllHosts'; Destination = 'profile.ps1' }
        )
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('SettingsFiles')) {
        $cfg | Add-Member -NotePropertyName SettingsFiles -NotePropertyValue @()
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('OhMyPosh')) {
        $cfg | Add-Member -NotePropertyName OhMyPosh -NotePropertyValue ([pscustomobject]@{
            BackupEnabled     = $true
            BackupAllThemes   = $true
            ThemeSourcePath   = '$env:POSH_THEMES_PATH'
            ThemeBackupPath   = 'Themes\\oh-my-posh'
            RestoreTargetPath = 'Themes\\oh-my-posh'
        })
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('Fonts')) {
        $cfg | Add-Member -NotePropertyName Fonts -NotePropertyValue ([pscustomobject]@{
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
        })
    }

    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('Provider')) {
        $cfg.Fonts | Add-Member -NotePropertyName Provider -NotePropertyValue 'NerdFonts'
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('DiscoveryEnabled')) {
        $cfg.Fonts | Add-Member -NotePropertyName DiscoveryEnabled -NotePropertyValue $true
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('Scope')) {
        $cfg.Fonts | Add-Member -NotePropertyName Scope -NotePropertyValue 'CurrentUser'
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('RequiredFonts')) {
        $cfg.Fonts | Add-Member -NotePropertyName RequiredFonts -NotePropertyValue @()
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('InventoryPath')) {
        $cfg.Fonts | Add-Member -NotePropertyName InventoryPath -NotePropertyValue 'Inventory\\fonts.json'
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('AutoDetectFromInstalled')) {
        $cfg.Fonts | Add-Member -NotePropertyName AutoDetectFromInstalled -NotePropertyValue $true
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('Files')) {
        $cfg.Fonts | Add-Member -NotePropertyName Files -NotePropertyValue @()
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('RestoreDirectory')) {
        $cfg.Fonts | Add-Member -NotePropertyName RestoreDirectory -NotePropertyValue '$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts'
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('WindowsTerminal')) {
        $cfg | Add-Member -NotePropertyName WindowsTerminal -NotePropertyValue ([pscustomobject]@{
            BackupEnabled      = $true
            SettingsSourcePath = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
            SettingsBackupPath = 'Settings\\windows-terminal\\settings.json'
            RestoreTargetPath  = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
        })
    }

    foreach ($item in @($cfg.Profiles)) {
        if ($null -eq $item) { continue }
        $item.Source = Resolve-TemplateValue -Value $item.Source
        $item.Destination = Resolve-TemplateValue -Value $item.Destination -RelativeRoot $cfg.ProfilesDirectory
    }

    foreach ($item in @($cfg.SettingsFiles)) {
        if ($null -eq $item) { continue }
        $item.Source = Resolve-TemplateValue -Value $item.Source
        $item.Destination = Resolve-TemplateValue -Value $item.Destination -RelativeRoot $cfg.SettingsDirectory
    }

    $cfg.OhMyPosh.ThemeSourcePath = Resolve-TemplateValue -Value $cfg.OhMyPosh.ThemeSourcePath
    $cfg.OhMyPosh.ThemeBackupPath = Resolve-TemplateValue -Value $cfg.OhMyPosh.ThemeBackupPath -RelativeRoot $cfg.RepoRoot
    $cfg.OhMyPosh.RestoreTargetPath = Resolve-TemplateValue -Value $cfg.OhMyPosh.RestoreTargetPath -RelativeRoot $cfg.RepoRoot

    $cfg.Fonts.InventoryPath = Resolve-TemplateValue -Value $cfg.Fonts.InventoryPath -RelativeRoot $cfg.RepoRoot
    $cfg.Fonts.RestoreDirectory = Resolve-TemplateValue -Value $cfg.Fonts.RestoreDirectory

    foreach ($item in @($cfg.Fonts.Files)) {
        if ($null -eq $item) { continue }
        if ($item.PSObject.Properties.Name.Contains('Source')) {
            $item.Source = Resolve-TemplateValue -Value $item.Source
        }
        if ($item.PSObject.Properties.Name.Contains('Destination')) {
            $item.Destination = Resolve-TemplateValue -Value $item.Destination -RelativeRoot $cfg.RepoRoot
        }
    }

    $cfg.WindowsTerminal.SettingsSourcePath = Resolve-TemplateValue -Value $cfg.WindowsTerminal.SettingsSourcePath
    $cfg.WindowsTerminal.SettingsBackupPath = Resolve-TemplateValue -Value $cfg.WindowsTerminal.SettingsBackupPath -RelativeRoot $cfg.RepoRoot
    $cfg.WindowsTerminal.RestoreTargetPath = Resolve-TemplateValue -Value $cfg.WindowsTerminal.RestoreTargetPath

    return $cfg
}