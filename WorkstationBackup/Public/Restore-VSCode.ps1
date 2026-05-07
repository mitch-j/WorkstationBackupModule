function Restore-VSCode {
    <#
    .SYNOPSIS
        Restore Visual Studio Code user settings and install extensions from backed-up list.
    .DESCRIPTION
        Restores VS Code user configuration files from backup and installs extensions
        that were previously backed up. Use -Force to reinstall all extensions even if
        they appear to be already installed.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath,
        [switch]$Force
    )

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path -Path (Get-WorkstationBackupRoot) -ChildPath 'powershell-sync.config.json'
    }

    $config = Read-PowerShellSyncConfig -Path $ConfigPath

    Restore-VSCodeUserSettings -Config $config
    Install-VSCodeExtensionsFromList -Config $config -Force:$Force
}