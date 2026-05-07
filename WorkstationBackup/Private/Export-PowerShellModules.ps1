function Export-PowerShellModules {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    # Export gallery modules manifest
    $installed = Get-InstalledGalleryModuleRecord
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

    # Export all installed modules manifest
    $allModules = Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase, Path | Sort-Object Name, Version
    $allModulesManifest = foreach ($module in $allModules) {
        [pscustomobject]@{
            Name       = $module.Name
            Version    = $module.Version.ToString()
            ModuleBase = $module.ModuleBase
            Path       = $module.Path
        }
    }

    $allModulesPath = Join-Path $Config.InventoryDirectory 'all-modules.json'
    if ($PSCmdlet.ShouldProcess($allModulesPath, 'Write all installed modules manifest')) {
        $allModulesManifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $allModulesPath -Encoding UTF8
    }

    Write-BackupLog -Message ('Exported all installed modules manifest with {0} entries.' -f @($allModulesManifest).Count)
}