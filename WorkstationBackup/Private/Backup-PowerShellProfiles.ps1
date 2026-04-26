function Backup-PowerShellProfiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($item in @($Config.Profiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Source)) {
            Write-BackupLog -Level WARN -Message "Profile source not found, skipping: $($item.Source)"
            continue
        }
        Copy-IfDifferent -Source $item.Source -Destination $item.Destination
    }
}