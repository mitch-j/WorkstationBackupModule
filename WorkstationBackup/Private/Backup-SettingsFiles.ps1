function Backup-SettingsFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($item in @($Config.SettingsFiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Source)) {
            Write-BackupLog -Level WARN -Message "Settings source not found, skipping: $($item.Source)"
            continue
        }
        Copy-IfDifferent -Source $item.Source -Destination $item.Destination
    }
}