function Restore-OhMyPoshThemes {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    if (-not $Config.OhMyPosh.BackupEnabled) {
        Write-BackupLog -Message 'Skipping oh-my-posh theme restore because it is disabled.'
        return
    }

    $backup = $Config.OhMyPosh.ThemeBackupPath
    $target = $Config.OhMyPosh.RestoreTargetPath

    if ($backup -eq $target) {
        Write-BackupLog -Message 'Skipping oh-my-posh restore because backup and restore targets are identical.'
        return
    }

    if (-not (Test-Path -LiteralPath $backup)) {
        Write-BackupLog -Level WARN -Message "oh-my-posh theme backup not found, skipping restore: $backup"
        return
    }

    Ensure-Directory -Path $target
    Get-ChildItem -LiteralPath $backup -Filter '*.omp.json' -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            Copy-IfDifferent -Source $_.FullName -Destination (Join-Path $target $_.Name)
        }
}