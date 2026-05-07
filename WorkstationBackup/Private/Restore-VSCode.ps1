function Restore-VSCodeUserSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    $backupPath = $Config.VisualStudioCode.UserSettingsBackupPath
    if (-not (Test-Path -Path $backupPath)) {
        throw "VS Code backup folder not found: $backupPath"
    }

    $restorePath = $Config.VisualStudioCode.RestoreTargetPath
    if (-not $restorePath) {
        throw "VisualStudioCode restore target path is not configured."
    }

    New-Directory -Path $restorePath

    $configFiles = @('settings.json', 'keybindings.json', 'locale.json', 'argv.json', 'extensions.json')
    foreach ($file in $configFiles) {
        $sourceFile = Join-Path -Path $backupPath -ChildPath $file
        if (Test-Path -Path $sourceFile) {
            $destFile = Join-Path -Path $restorePath -ChildPath $file
            Copy-IfDifferent -Source $sourceFile -Destination $destFile
        }
    }

    $backupSnippets = Join-Path -Path $backupPath -ChildPath 'snippets'
    if (Test-Path -Path $backupSnippets) {
        Copy-Item -Path $backupSnippets -Destination $restorePath -Recurse -Force -ErrorAction Stop
    }

    Write-BackupLog -Message "Restored VS Code config files from '$backupPath' to '$restorePath'."
}

function Install-VSCodeExtensionsFromList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,
        [switch]$Force
    )

    $backupPath = $Config.VisualStudioCode.ExtensionsListBackupPath
    if (-not (Test-Path -Path $backupPath)) {
        throw "VS Code extension list not found: $backupPath"
    }

    $extensions = Get-Content -Path $backupPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if (-not $extensions) {
        Write-Warning "The extension list at '$backupPath' is empty."
        return
    }

    $codePath = Get-VSCodeCliPath -ThrowIfMissing
    $installedExtensions = & $codePath --list-extensions 2>$null | Sort-Object -Unique

    foreach ($extension in $extensions) {
        if ($Force -or ($installedExtensions -notcontains $extension)) {
            Write-BackupLog -Message "Installing VS Code extension: $extension"
            & $codePath --install-extension $extension --force | Out-Null
        } else {
            Write-Verbose "Extension already installed: $extension"
        }
    }
}