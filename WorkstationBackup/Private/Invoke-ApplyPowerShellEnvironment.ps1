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

    if ($PSCmdlet.ShouldProcess('PSModulePath', 'Synchronize module path')) {
        Sync-PSModulePath -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Config directories', 'Initialize configuration directories')) {
        Initialize-ConfigDirectory -Config $Config
    }

    # Bootstrap runtime dependencies first.
    if ($PSCmdlet.ShouldProcess('PowerShell modules', 'Import PowerShell modules')) {
        Import-PowerShellModule -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Font restore prerequisites', 'Initialize font restore prerequisites')) {
        Initialize-FontRestorePrerequisite -Config $Config -SkipFontInstallFailures:$SkipFontInstallFailures | Out-Null
    }

    # Apply repo-managed state.
    if ($PSCmdlet.ShouldProcess('PowerShell profiles', 'Restore PowerShell profiles')) {
        Restore-PowerShellProfiles -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Settings files', 'Restore settings files')) {
        Restore-SettingsFiles -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Oh My Posh themes', 'Restore Oh My Posh themes')) {
        Restore-OhMyPoshTheme -Config $Config
    }
    
    if ($PSCmdlet.ShouldProcess('Nerd fonts', 'Restore Nerd fonts')) {
        Restore-NerdFonts -Config $Config -SkipFontInstallFailures:$SkipFontInstallFailures
    }
    
    if ($PSCmdlet.ShouldProcess('Windows Terminal settings', 'Restore Windows Terminal settings')) {
        Restore-WindowsTerminal -Config $Config
    }

}