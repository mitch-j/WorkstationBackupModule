function Invoke-ExportPowerShellEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter()]
        [switch]$UpdateFontConfigFromDiscovery
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if ($PSCmdlet.ShouldProcess('PSModulePath', 'Synchronize module path')) {
        Sync-PSModulePath -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Config directories', 'Initialize configuration directories')) {
        Initialize-ConfigDirectory -Config $Config
    }

    if ($PSCmdlet.ShouldProcess('PowerShell profiles', 'Backup PowerShell profiles')) {
        Backup-PowerShellProfile -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Settings files', 'Backup settings files')) {
        Backup-SettingsFile -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Oh My Posh themes', 'Backup Oh My Posh themes')) {
        Backup-OhMyPoshTheme -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Nerd fonts', 'Export Nerd fonts')) {
        Export-NerdFont -Config $Config -UpdateFontConfigFromDiscovery:$UpdateFontConfigFromDiscovery
    }
    
    if ($PSCmdlet.ShouldProcess('Windows Terminal settings', 'Backup Windows Terminal settings')) {
        Backup-WindowsTerminal -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('PowerShell modules', 'Export PowerShell modules')) {
        Export-PowerShellModule -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Machine state', 'Export machine state')) {
        Export-MachineState -Config $Config
    }
}