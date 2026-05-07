function Backup-VSCode {
    <#
    .SYNOPSIS
        Backup Visual Studio Code user settings and installed extension list.
    .DESCRIPTION
        Backs up VS Code user configuration files (settings.json, keybindings.json, etc.) and
        generates a list of currently installed extensions for later restoration.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [string]$ConfigPath
    )

    if (-not $ConfigPath) {
        $ConfigPath = Join-Path -Path (Get-WorkstationBackupRoot) -ChildPath 'powershell-sync.config.json'
    }

    $config = Read-PowerShellSyncConfig -Path $ConfigPath

    Backup-VSCodeUserSettings -Config $config
    Backup-VSCodeExtensionsList -Config $config
}