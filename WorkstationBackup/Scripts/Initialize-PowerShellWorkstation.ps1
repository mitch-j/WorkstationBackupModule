[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RepoUrl,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = 'C:\Dev\work\ps-config-work',

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [bool]$InstallPackages = $true,

    [Parameter()]
    [string[]]$ChocolateyPackages = @(
        'git',
        'powershell-core',
        'oh-my-posh',
        'microsoft-windows-terminal',
        'vscode'
    ),

    [Parameter()]
    [switch]$SkipClone,

    [Parameter()]
    [bool]$ApplyConfig = $true,

    [Parameter()]
    [switch]$RegisterScheduledTask,

    [Parameter()]
    [ValidateRange(1, 28)]
    [int]$ScheduledDayOfMonth = 1,

    [Parameter()]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$ScheduledTime = '09:00',

    [Parameter()]
    [bool]$SkipGitDuringApply = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $moduleRoot 'WorkstationBackup.psd1') -Force

Write-BackupLog 'Initialize-PowerShellWorkstation is still intentionally script-driven during the refactor.'
Write-BackupLog 'Clone/update and package installation logic should be migrated next.'

if (-not $SkipClone) {
    if (Test-Path -LiteralPath $RepoRoot) {
        Write-BackupLog "Repository directory exists at '$RepoRoot'. Pulling latest changes."
        if ($PSCmdlet.ShouldProcess($RepoRoot, 'Pull latest changes from git repository')) {
            Push-Location $RepoRoot
            try {
                & git pull --rebase
                if ($LASTEXITCODE -ne 0) {
                    throw 'Git pull failed.'
                }
            }
            finally {
                Pop-Location
            }
        }
    }
    else {
        Write-BackupLog "Cloning repository from '$RepoUrl' to '$RepoRoot'."
        if ($PSCmdlet.ShouldProcess($RepoRoot, 'Clone git repository')) {
            & git clone $RepoUrl $RepoRoot
            if ($LASTEXITCODE -ne 0) {
                throw 'Git clone failed.'
            }
        }
    }
}

if ($InstallPackages) {
    Write-BackupLog ('Installing baseline packages: ' + ($ChocolateyPackages -join ', '))

    foreach ($package in $ChocolateyPackages) {
        if ($PSCmdlet.ShouldProcess($package, 'Install Chocolatey package')) {
            & choco install $package -y
            if ($LASTEXITCODE -ne 0) {
                Write-BackupLog -Level 'WARN' -Message "Failed to install package '$package'."
            }
        }
    }
}

if ($ApplyConfig) {
    $importParameters = @{
        RepoRoot = $RepoRoot
        SkipGit  = $SkipGitDuringApply
    }
    if ($ConfigPath) { $importParameters.ConfigPath = $ConfigPath }
    if ($WhatIfPreference) { $importParameters.WhatIf = $true }

    Import-PowerShellEnvironment @importParameters
}

if ($RegisterScheduledTask) {
    Register-WorkstationBackupTask -RepoRoot $RepoRoot -ScheduledDayOfMonth $ScheduledDayOfMonth -ScheduledTime $ScheduledTime -WhatIf:$WhatIfPreference
}
