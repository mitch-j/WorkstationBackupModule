function Backup-PowerShellProfile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    foreach ($item in @($Config.Profiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        
        $resolvedSource = Resolve-BackupPath -Path $item.Source
        
        if (-not (Test-Path -LiteralPath $resolvedSource)) {
            Write-BackupLog -Level WARN -Message "Profile source not found, skipping: $resolvedSource"
            continue
        }
        if ($PSCmdlet.ShouldProcess($item.Destination, 'Copy PowerShell profile')) {
            Copy-IfDifferent -Source $resolvedSource -Destination $item.Destination
        }
    }
}