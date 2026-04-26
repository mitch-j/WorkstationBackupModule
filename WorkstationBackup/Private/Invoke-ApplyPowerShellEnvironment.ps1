# Private/Invoke-ApplyPowerShellEnvironment.ps1
function Invoke-ApplyPowerShellEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter()]
        [switch]$SkipFontInstallFailures
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    Sync-PSModulePath -Config $Config
    Initialize-ConfigDirectories -Config $Config

    # Bootstrap dependencies first
    Import-PowerShellModules -Config $Config

    # Optional font prerequisite/bootstrap stage
    if (Get-Command -Name Initialize-FontRestorePrerequisites -ErrorAction SilentlyContinue) {
        Initialize-FontRestorePrerequisites -Config $Config -SkipFailures:$SkipFontInstallFailures
    }

    Restore-PowerShellProfiles -Config $Config
    Restore-SettingsFiles -Config $Config
    Restore-OhMyPoshThemes -Config $Config

    if (Get-Command -Name Restore-NerdFonts -ErrorAction SilentlyContinue) {
        Restore-NerdFonts -Config $Config -SkipFailures:$SkipFontInstallFailures
    }

    Restore-WindowsTerminal -Config $Config
}