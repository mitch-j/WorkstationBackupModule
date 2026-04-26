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

    # Bootstrap runtime dependencies first.
    Import-PowerShellModules -Config $Config
    Initialize-FontRestorePrerequisites -Config $Config -SkipFontInstallFailures:$SkipFontInstallFailures | Out-Null

    # Apply repo-managed state.
    Restore-PowerShellProfiles -Config $Config
    Restore-SettingsFiles -Config $Config
    Restore-OhMyPoshThemes -Config $Config
    Restore-NerdFonts -Config $Config -SkipFontInstallFailures:$SkipFontInstallFailures
    Restore-WindowsTerminal -Config $Config

}