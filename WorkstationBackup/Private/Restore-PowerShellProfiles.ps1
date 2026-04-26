function Restore-PowerShellProfiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($item in @($Config.Profiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Destination)) {
            Write-BackupLog -Level WARN -Message "Profile backup not found, skipping restore: $($item.Destination)"
            continue
        }
        Copy-IfDifferent -Source $item.Destination -Destination $item.Source
    }
}