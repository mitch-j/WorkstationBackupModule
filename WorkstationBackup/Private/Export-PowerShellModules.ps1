function Export-PowerShellModules {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $installed = Get-InstalledGalleryModuleRecords
    $manifest = foreach ($module in $installed) {
        [pscustomobject]@{
            Name       = $module.Name
            Version    = $module.Version.ToString()
            Repository = if ($module.Repository) { $module.Repository } else { $Config.DefaultRepository }
        }
    }

    $manifestPath = Join-Path $Config.InventoryDirectory 'gallery-modules.json'
    if ($PSCmdlet.ShouldProcess($manifestPath, 'Write external module manifest')) {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }

    Write-BackupLog -Message ('Exported gallery module manifest with {0} entries.' -f @($manifest).Count)
}