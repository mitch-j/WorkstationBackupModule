function Update-ConfigFontsFromDiscovery {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter(Mandatory)]
        [string[]]$DiscoveredFonts
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $configPath = $null
    if ($Config.PSObject.Properties.Name.Contains('ConfigPath')) {
        $configPath = $Config.ConfigPath
    }

    if ([string]::IsNullOrWhiteSpace($configPath)) {
        Write-BackupLog -Level 'WARN' -Message 'ConfigPath is not present on the config object. Skipping font config update.'
        return
    }

    if (-not (Test-Path -LiteralPath $configPath)) {
        Write-BackupLog -Level 'WARN' -Message "Config file not found. Skipping font config update: $configPath"
        return
    }

    $raw = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 50

    if (-not $raw.PSObject.Properties.Name.Contains('Fonts') -or $null -eq $raw.Fonts) {
        $raw | Add-Member -NotePropertyName Fonts -NotePropertyValue ([pscustomobject]@{})
    }

    $raw.Fonts.Provider = if ($Config.Fonts.Provider) { $Config.Fonts.Provider } else { 'NerdFonts' }
    $raw.Fonts.RequiredFonts = @($DiscoveredFonts | Sort-Object -Unique)

    if (-not $raw.Fonts.PSObject.Properties.Name.Contains('InventoryPath') -or [string]::IsNullOrWhiteSpace($raw.Fonts.InventoryPath)) {
        $raw.Fonts | Add-Member -NotePropertyName InventoryPath -NotePropertyValue 'Inventory\\fonts.json' -Force
    }

    Write-BackupLog -Message "Updating config font list at $configPath"

    if ($PSCmdlet.ShouldProcess($configPath, 'Write updated font configuration')) {
        $raw | ConvertTo-Json -Depth 50 | Set-Content -LiteralPath $configPath -Encoding UTF8
    }
}