# Private/Invoke-ExportPowerShellEnvironment.ps1
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

    Sync-PSModulePath -Config $Config
    Initialize-ConfigDirectories -Config $Config

    Backup-PowerShellProfiles -Config $Config
    Backup-SettingsFiles -Config $Config
    Backup-OhMyPoshThemes -Config $Config
    Export-NerdFonts -Config $Config -UpdateFontConfigFromDiscovery:$UpdateFontConfigFromDiscovery
    Backup-WindowsTerminal -Config $Config
    Export-PowerShellModules -Config $Config
    Export-MachineState -Config $Config
}