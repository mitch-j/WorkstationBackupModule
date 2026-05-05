function Initialize-ConfigDirectory {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($path in @(
        $Config.RepoRoot,
        $Config.PersonalModulesPath,
        $Config.ExternalModulesPath,
        $Config.ProfilesDirectory,
        $Config.ThemesDirectory,
        $Config.FontsDirectory,
        $Config.LogDirectory
    )) {
        if ($PSCmdlet.ShouldProcess($path, 'Create config directory')) {
            New-Directory -Path $path
        }
    }
}