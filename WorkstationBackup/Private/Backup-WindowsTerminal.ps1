function Backup-WindowsTerminal {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    if (-not $Config.WindowsTerminal.BackupEnabled) {
        Write-BackupLog -Message 'Skipping Windows Terminal backup because it is disabled.'
        return
    }

    $source = $Config.WindowsTerminal.SettingsSourcePath
    $backup = $Config.WindowsTerminal.SettingsBackupPath

    if (-not (Test-Path -LiteralPath $source)) {
        Write-BackupLog -Level WARN -Message "Windows Terminal settings not found, skipping backup: $source"
        return
    }

    Copy-IfDifferent -Source $source -Destination $backup

    try {
        $json = Get-Content -LiteralPath $source -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 50
        $profiles = @()
        if ($json.profiles -and $json.profiles.list) {
            foreach ($profile in @($json.profiles.list)) {
                $profiles += [pscustomobject]@{
                    Name     = $profile.name
                    FontFace = $profile.font.face
                    FontSize = $profile.font.size
                }
            }
        }

        $summary = [pscustomobject]@{
            ExportedAt     = (Get-Date).ToString('s')
            DefaultProfile = $json.defaultProfile
            Profiles       = $profiles
        }

        $summaryPath = Join-Path $Config.InventoryDirectory 'windows-terminal-summary.json'
        if ($PSCmdlet.ShouldProcess($summaryPath, 'Write Windows Terminal summary')) {
            $summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
        }
    }
    catch {
        Write-BackupLog -Level WARN -Message "Failed to parse Windows Terminal settings summary: $($_.Exception.Message)"
    }
}