<#
.SYNOPSIS
    Bootstraps a new Windows workstation by cloning a repo, installing packages, and applying configuration.

.DESCRIPTION
    This script is a wrapper for initial workstation setup. It can clone or update a repository,
    install baseline Chocolatey packages, optionally apply PowerShell environment configuration,
    and register a scheduled backup task.

.PARAMETER RepoUrl
    The Git repository URL to clone for workstation configuration.

.PARAMETER RepoRoot
    Local path where the repository will be cloned or updated.

.PARAMETER ConfigPath
    Optional path to the powershell-sync.config.json file to use during configuration application.

.PARAMETER InstallPackages
    If true, installs the baseline Chocolatey packages.

.PARAMETER ChocolateyPackages
    List of Chocolatey package names to install.

.PARAMETER SkipClone
    If specified, skip repository cloning or update.

.PARAMETER ApplyConfig
    If specified, apply configuration after cloning/updating the repo.

.PARAMETER RegisterScheduledTask
    If specified, register a workstation backup scheduled task after configuration.

.PARAMETER ScheduledDayOfMonth
    Day of month for the scheduled task.

.PARAMETER ScheduledTime
    Time of day for the scheduled task, in HH:mm format.

.PARAMETER SkipGitDuringApply
    If true, skip Git sync while applying configuration.

.EXAMPLE
    .\Initialize-PowerShellWorkstation.ps1 -RepoUrl 'https://github.com/me/backup-repo.git' -RepoRoot 'C:\Dev\work\backup-repo'

    Clones the backup repository and applies the configuration.

.NOTES
    - This script is intentionally a wrapper and may be migrated into module functions later.
    - Use `-WhatIf` to preview the operations if running from PowerShell.

.INPUTS
    None.

.OUTPUTS
    None.
#>
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
