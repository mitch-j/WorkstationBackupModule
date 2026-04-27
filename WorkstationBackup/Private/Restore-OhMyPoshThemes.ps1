function Restore-OhMyPoshTheme {
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

    if ($PSCmdlet.ShouldProcess($target, 'Create directory')) {
        New-Directory -Path $target
    }
    
    Get-ChildItem -LiteralPath $backup -Filter '*.omp.json' -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            $destination = Join-Path $target $_.Name
            if ($PSCmdlet.ShouldProcess($destination, 'Copy oh-my-posh theme file')) {
                Copy-IfDifferent -Source $_.FullName -Destination $destination
            }
        }
}