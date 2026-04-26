function Backup-OhMyPoshThemes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    if (-not $Config.OhMyPosh.BackupEnabled) {
        Write-BackupLog -Message 'Skipping oh-my-posh theme backup because it is disabled.'
        return
    }

    $source = $Config.OhMyPosh.ThemeSourcePath
    $destination = $Config.OhMyPosh.ThemeBackupPath
    Ensure-Directory -Path $destination

    if (Test-Path -LiteralPath $source -PathType Container) {
        $themeFiles = Get-ChildItem -LiteralPath $source -Filter '*.omp.json' -File -ErrorAction SilentlyContinue
        foreach ($file in $themeFiles) {
            $target = Join-Path $destination $file.Name
            Copy-IfDifferent -Source $file.FullName -Destination $target
        }
        return
    }

    if (Test-Path -LiteralPath $source -PathType Leaf) {
        $target = if (Test-Path -LiteralPath $destination -PathType Container) {
            Join-Path $destination (Split-Path -Path $source -Leaf)
        }
        else {
            $destination
        }
        Copy-IfDifferent -Source $source -Destination $target
        return
    }

    Write-BackupLog -Level WARN -Message "oh-my-posh theme source not found, skipping: $source"
}