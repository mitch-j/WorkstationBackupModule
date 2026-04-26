function Import-PowerShellModules {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter()]
        [switch]$PruneExternalModules
    )

    $manifestPath = Join-Path $Config.InventoryDirectory 'gallery-modules.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-BackupLog -Level WARN -Message "Gallery module manifest not found, skipping install: $manifestPath"
        return
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    if ($null -eq $manifest) {
        Write-BackupLog -Message 'Gallery module manifest is empty, nothing to install.'
        return
    }

    foreach ($entry in @($manifest)) {
        $targetVersionPath = Join-Path (Join-Path $Config.ExternalModulesPath $entry.Name) $entry.Version
        if (Test-Path -LiteralPath $targetVersionPath) {
            Write-BackupLog -Message ("External module already present: {0} {1}" -f $entry.Name, $entry.Version)
            continue
        }

        $params = @{
            Name            = $entry.Name
            Path            = $Config.ExternalModulesPath
            RequiredVersion = $entry.Version
            Force           = $true
        }
        if ($entry.Repository) {
            $params.Repository = $entry.Repository
        }

        Write-BackupLog -Message ("Saving module {0} {1} to {2}" -f $entry.Name, $entry.Version, $Config.ExternalModulesPath)
        if ($PSCmdlet.ShouldProcess(("$($entry.Name):$($entry.Version)"), 'Save PowerShell module')) {
            Save-Module @params
        }
    }

    if ($PruneExternalModules) {
        Write-BackupLog -Level WARN -Message 'PruneExternalModules was specified. Remove untracked versions manually if needed; automatic prune is not implemented.'
    }
}