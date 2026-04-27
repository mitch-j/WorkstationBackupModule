function Export-NerdFont {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter()]
        [switch]$UpdateFontConfigFromDiscovery
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $Config.Fonts.BackupEnabled) {
        Write-BackupLog -Message 'Skipping font export because it is disabled.'
        return
    }

    $desiredFonts = @(Get-DesiredNerdFontFamily -Config $Config)
    $discoveredFonts = @()

    if ($Config.Fonts.DiscoveryEnabled) {
        $discoveredFonts = @(Get-InstalledNerdFontFamily -Config $Config)
    }

    $payload = [pscustomobject]@{
        Provider          = if ($Config.Fonts.Provider) { $Config.Fonts.Provider } else { 'NerdFonts' }
        ExportedAt        = (Get-Date).ToString('s')
        RequiredFonts     = @($desiredFonts)
        DiscoveredFonts   = @($discoveredFonts)
        MissingFromConfig = @($discoveredFonts | Where-Object { $_ -notin $desiredFonts } | Sort-Object -Unique)
        MissingFromSystem = @($desiredFonts | Where-Object { $_ -notin $discoveredFonts } | Sort-Object -Unique)
    }

    $inventoryPath = $Config.Fonts.InventoryPath
    $inventoryDirectory = Split-Path -Path $inventoryPath -Parent

    if ($inventoryDirectory) {
        New-Directory -Path $inventoryDirectory
    }

    if ($PSCmdlet.ShouldProcess($inventoryPath, 'Write font inventory')) {
        $payload | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $inventoryPath -Encoding UTF8
    }

    Write-BackupLog -Message ('Exported Nerd Font inventory with {0} desired font(s) and {1} discovered font(s).' -f $desiredFonts.Count, $discoveredFonts.Count)

    if ($payload.MissingFromConfig.Count -gt 0) {
        Write-BackupLog -Level 'WARN' -Message ('Installed Nerd Fonts missing from config: {0}' -f ($payload.MissingFromConfig -join ', '))
    }

    if ($payload.MissingFromSystem.Count -gt 0) {
        Write-BackupLog -Level 'WARN' -Message ('Configured Nerd Fonts not currently installed: {0}' -f ($payload.MissingFromSystem -join ', '))
    }

    if ($UpdateFontConfigFromDiscovery) {
        Update-ConfigFontsFromDiscovery -Config $Config -DiscoveredFonts $discoveredFonts
    }
}