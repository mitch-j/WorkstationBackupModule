function Restore-PowerShellProfile {
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
        
        $resolvedDestination = Resolve-BackupPath -Path $item.Source
        
        if ($PSCmdlet.ShouldProcess($item.Source, 'Restore PowerShell profile')) {
            Copy-IfDifferent -Source $item.Destination -Destination $resolvedDestination
        }
    }
}