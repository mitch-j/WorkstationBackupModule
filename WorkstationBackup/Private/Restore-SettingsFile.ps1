function Restore-SettingsFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($item in @($Config.SettingsFiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Destination)) {
            Write-BackupLog -Level WARN -Message "Settings backup not found, skipping restore: $($item.Destination)"
            continue
        }
        
        $resolvedDestination = Resolve-BackupPath -Path $item.Source
        
        if ($PSCmdlet.ShouldProcess($item.Source, 'Restore settings file')) {
            Copy-IfDifferent -Source $item.Destination -Destination $resolvedDestination
        }
    }
}