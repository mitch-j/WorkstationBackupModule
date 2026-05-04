function Restore-WindowsTerminal {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    if (-not $Config.WindowsTerminal.BackupEnabled) {
        Write-BackupLog -Message 'Skipping Windows Terminal restore because it is disabled.'
        return
    }

    $backup = $Config.WindowsTerminal.SettingsBackupPath
    $target = $Config.WindowsTerminal.RestoreTargetPath

    if (-not (Test-Path -LiteralPath $backup)) {
        Write-BackupLog -Level WARN -Message "Windows Terminal backup not found, skipping restore: $backup"
        return
    }

    if ($PSCmdlet.ShouldProcess($target, 'Restore Windows Terminal settings')) {
        Copy-IfDifferent -Source $backup -Destination $target
    }
}