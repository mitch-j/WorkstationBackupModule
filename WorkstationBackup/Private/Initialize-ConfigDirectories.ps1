function Initialize-ConfigDirectories {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($path in @(
        $Config.RepoRoot,
        $Config.PersonalModulesPath,
        $Config.ExternalModulesPath,
        $Config.InventoryDirectory,
        $Config.ProfilesDirectory,
        $Config.SettingsDirectory,
        $Config.ThemesDirectory,
        $Config.FontsDirectory,
        $Config.LogDirectory
    )) {
        Ensure-Directory -Path $path
    }
}