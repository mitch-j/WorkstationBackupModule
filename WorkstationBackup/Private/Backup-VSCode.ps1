function Backup-VSCodeUserSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    if (-not $Config.VisualStudioCode.BackupEnabled) {
        Write-Verbose "VisualStudioCode backup is disabled in config."
        return
    }

    $sourcePath = $Config.VisualStudioCode.UserSettingsSourcePath
    if (-not (Test-Path -Path $sourcePath)) {
        throw "VS Code user settings folder not found: $sourcePath"
    }

    $backupPath = $Config.VisualStudioCode.UserSettingsBackupPath
    New-Directory -Path $backupPath

    $configFiles = @('settings.json', 'keybindings.json', 'locale.json', 'argv.json', 'extensions.json')
    foreach ($file in $configFiles) {
        $sourceFile = Join-Path -Path $sourcePath -ChildPath $file
        if (Test-Path -Path $sourceFile) {
            $destFile = Join-Path -Path $backupPath -ChildPath $file
            Copy-IfDifferent -Source $sourceFile -Destination $destFile
        }
    }

    $sourceSnippets = Join-Path -Path $sourcePath -ChildPath 'snippets'
    if (Test-Path -Path $sourceSnippets) {
        Copy-Item -Path $sourceSnippets -Destination $backupPath -Recurse -Force -ErrorAction Stop
    }

    Write-BackupLog -Message "Backed up VS Code config files from '$sourcePath' to '$backupPath'."
}

function Backup-VSCodeExtensionsList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    if (-not $Config.VisualStudioCode.BackupEnabled) {
        Write-Verbose "VisualStudioCode backup is disabled in config."
        return
    }

    $extensions = Get-VSCodeInstalledExtensions
    if (-not $extensions) {
        Write-Warning "No installed VS Code extensions were discovered."
    }

    $backupPath = $Config.VisualStudioCode.ExtensionsListBackupPath
    New-Directory -Path (Split-Path -Path $backupPath -Parent)
    $extensions | Set-Content -Path $backupPath -Encoding utf8

    Write-BackupLog -Message "Backed up VS Code extension list to '$backupPath'."
}

function Get-VSCodeInstalledExtensions {
    [CmdletBinding()]
    param()

    $extensions = @()
    $codePath = Get-VSCodeCliPath

    if ($codePath) {
        try {
            $extensions = & $codePath --list-extensions 2>$null | Sort-Object -Unique
            if ($extensions) {
                return $extensions
            }
        } catch {
            Write-Verbose "VS Code CLI lookup failed: $_"
        }
    }

    $probePaths = @(
        "$env:USERPROFILE\.vscode\extensions",
        "$env:USERPROFILE\.vscode-insiders\extensions"
    )

    foreach ($path in $probePaths) {
        if (Test-Path -Path $path) {
            $extensions += Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        }
    }

    return $extensions | Sort-Object -Unique
}

function Get-VSCodeCliPath {
    [CmdletBinding()]
    param(
        [switch]$ThrowIfMissing
    )

    $candidates = @(
        'code',
        'code.cmd',
        'code.exe',
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code",
        "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles\Microsoft VS Code\bin\code",
        "$env:ProgramFiles(x86)\Microsoft VS Code\bin\code.cmd",
        "$env:ProgramFiles(x86)\Microsoft VS Code\bin\code"
    )

    foreach ($candidate in $candidates) {
        try {
            $commandInfo = Get-Command -CommandType Application -Name $candidate -ErrorAction Stop
            if ($commandInfo) {
                return $commandInfo.Source
            }
        } catch {
            continue
        }
    }

    if ($ThrowIfMissing) {
        throw "Visual Studio Code CLI 'code' was not found on PATH or in standard install locations."
    }

    return $null
}