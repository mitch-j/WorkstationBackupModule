<##
.SYNOPSIS
Bootstraps a new Windows workstation for a Git-backed PowerShell environment.

.DESCRIPTION
Initialize-PowerShellWorkstation.ps1 prepares a new machine to use the PowerShell
sync repository.

The script can:
- verify administrative prerequisites where needed
- install common dependencies with Chocolatey
- clone or update the PowerShell config repository
- validate the expected config file
- run Sync-PowerShellEnvironment.ps1 in Apply mode
- optionally register the monthly scheduled sync task

This is intended for first-time setup on a new workstation.

.PARAMETER RepoUrl
Git URL for the PowerShell configuration repository.

.PARAMETER RepoRoot
Local path where the repository should live.

Default: C:\Dev\work\ps-config-work

.PARAMETER ConfigPath
Path to powershell-sync.config.json.

Default: <RepoRoot>\powershell-sync.config.json

.PARAMETER ScriptPath
Path to Sync-PowerShellEnvironment.ps1.

Default: <RepoRoot>\Scripts\Sync-PowerShellEnvironment.ps1

.PARAMETER InstallPackages
Install baseline packages using Chocolatey.

Default: True

.PARAMETER ChocolateyPackages
List of Chocolatey package IDs to install when InstallPackages is enabled.

Default:
- git
- powershell-core
- oh-my-posh
- microsoft-windows-terminal
- vscode

.PARAMETER SkipClone
Skip clone or pull/update of the repository.

.PARAMETER ApplyConfig
Run Sync-PowerShellEnvironment.ps1 in Apply mode after prerequisites and repo setup.

Default: True

.PARAMETER RegisterScheduledTask
Register the monthly sync scheduled task after Apply completes.

.PARAMETER ScheduledDayOfMonth
Day of month used for the scheduled sync task.

Default: 1

.PARAMETER ScheduledTime
Time of day for the scheduled sync task in HH:mm format.

Default: 09:00

.PARAMETER SkipGitDuringApply
Pass -SkipGit to the sync script during Apply.

Default: True

.PARAMETER ForcePull
If the repository already exists, run git pull --rebase --autostash before applying.

.PARAMETER WhatIf
Preview actions without making changes where supported.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Initialize-PowerShellWorkstation.ps1 -RepoUrl https://github.com/your-org/ps-config-work.git

Installs prerequisites, clones the repository, and applies the saved PowerShell environment.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Initialize-PowerShellWorkstation.ps1 -RepoUrl https://github.com/your-org/ps-config-work.git -RegisterScheduledTask -ScheduledDayOfMonth 1 -ScheduledTime 10:00

Bootstraps the workstation and registers the monthly sync task.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Initialize-PowerShellWorkstation.ps1 -RepoUrl https://github.com/your-org/ps-config-work.git -WhatIf

Shows what the bootstrap would do without making changes.
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
    [string]$ScriptPath,

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
    [ValidateRange(1,31)]
    [int]$ScheduledDayOfMonth = 1,

    [Parameter()]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$ScheduledTime = '09:00',

    [Parameter()]
    [bool]$SkipGitDuringApply = $true,

    [Parameter()]
    [switch]$ForcePull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $RepoRoot 'powershell-sync.config.json'
}

if (-not $ScriptPath) {
    $ScriptPath = Join-Path $RepoRoot 'Scripts\Sync-PowerShellEnvironment.ps1'
}

function Write-InitLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host ('[{0}] [{1}] {2}' -f $timestamp, $Level, $Message)
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$InstallHint
    )

    if (-not (Get-Command -Name $Name -ErrorAction SilentlyContinue)) {
        $message = "Required command '$Name' was not found."
        if ($InstallHint) {
            $message = "$message $InstallHint"
        }
        throw $message
    }
}

function Install-ChocolateyPackages {
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages
    )

    Assert-CommandExists -Name 'choco' -InstallHint 'Install Chocolatey first or rerun with -InstallPackages $false.'

    foreach ($package in $Packages) {
        if ([string]::IsNullOrWhiteSpace($package)) {
            continue
        }

        Write-InitLog "Ensuring Chocolatey package '$package' is installed"
        if ($PSCmdlet.ShouldProcess("Chocolatey package $package", 'Install or upgrade')) {
            & choco upgrade $package -y --no-progress
            if ($LASTEXITCODE -ne 0) {
                throw "Chocolatey failed while installing or upgrading package '$package'. Exit code: $LASTEXITCODE"
            }
        }
    }
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-InitLog "Creating directory $Path"
        if ($PSCmdlet.ShouldProcess($Path, 'Create directory')) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
}

function Sync-Repository {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$SkipSync,

        [Parameter()]
        [switch]$Pull
    )

    if ($SkipSync) {
        Write-InitLog 'Skipping repository clone/update by request' 'WARN'
        return
    }

    Assert-CommandExists -Name 'git' -InstallHint 'Install Git or enable -InstallPackages.'

    $parent = Split-Path -Path $Path -Parent
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    $gitDir = Join-Path $Path '.git'
    if (Test-Path -LiteralPath $gitDir) {
        Write-InitLog "Repository already exists at $Path"
        if ($Pull) {
            Write-InitLog 'Pulling latest repository changes'
            if ($PSCmdlet.ShouldProcess($Path, 'git pull --rebase --autostash')) {
                Push-Location $Path
                try {
                    & git pull --rebase --autostash
                    if ($LASTEXITCODE -ne 0) {
                        throw "git pull failed with exit code $LASTEXITCODE"
                    }
                }
                finally {
                    Pop-Location
                }
            }
        }
        return
    }

    if (Test-Path -LiteralPath $Path) {
        $existingItems = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        if ($existingItems) {
            throw "Target path '$Path' exists but is not a Git repository. Clear it or use a different RepoRoot."
        }
    }

    Write-InitLog "Cloning repository from $Url to $Path"
    if ($PSCmdlet.ShouldProcess($Path, "git clone $Url")) {
        & git clone $Url $Path
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed with exit code $LASTEXITCODE"
        }
    }
}

function Assert-FileExists {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description not found at '$Path'."
    }
}

function Invoke-SyncScriptApply {
    param(
        [Parameter(Mandatory)]
        [string]$SyncScriptPath,

        [Parameter(Mandatory)]
        [string]$SyncConfigPath,

        [Parameter()]
        [bool]$UseSkipGit = $true
    )

    Assert-FileExists -Path $SyncScriptPath -Description 'Sync script'
    Assert-FileExists -Path $SyncConfigPath -Description 'Sync configuration file'

    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $SyncScriptPath,
        '-Mode', 'Apply',
        '-ConfigPath', $SyncConfigPath
    )

    if ($UseSkipGit) {
        $arguments += '-SkipGit'
    }

    if ($WhatIf) {
        $arguments += '-WhatIf'
    }

    Write-InitLog 'Running Sync-PowerShellEnvironment.ps1 in Apply mode'
    if ($PSCmdlet.ShouldProcess($SyncScriptPath, 'Apply PowerShell environment')) {
        & pwsh @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Sync-PowerShellEnvironment.ps1 Apply failed with exit code $LASTEXITCODE"
        }
    }
}

function Invoke-SyncScriptRegisterTask {
    param(
        [Parameter(Mandatory)]
        [string]$SyncScriptPath,

        [Parameter(Mandatory)]
        [string]$SyncConfigPath,

        [Parameter(Mandatory)]
        [int]$DayOfMonth,

        [Parameter(Mandatory)]
        [string]$Time
    )

    Assert-FileExists -Path $SyncScriptPath -Description 'Sync script'
    Assert-FileExists -Path $SyncConfigPath -Description 'Sync configuration file'

    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $SyncScriptPath,
        '-Mode', 'RegisterScheduledTask',
        '-ConfigPath', $SyncConfigPath,
        '-ScheduledDayOfMonth', $DayOfMonth,
        '-ScheduledTime', $Time
    )

    if ($WhatIf) {
        $arguments += '-WhatIf'
    }

    Write-InitLog "Registering monthly sync task for day $DayOfMonth at $Time"
    if ($PSCmdlet.ShouldProcess($SyncScriptPath, 'Register scheduled sync task')) {
        & pwsh @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Sync-PowerShellEnvironment.ps1 RegisterScheduledTask failed with exit code $LASTEXITCODE"
        }
    }
}

try {
    Write-InitLog 'Starting workstation initialization'

    if ($InstallPackages -and -not (Test-IsAdministrator)) {
        Write-InitLog 'Chocolatey installs usually require an elevated PowerShell session' 'WARN'
    }

    if ($InstallPackages) {
        Install-ChocolateyPackages -Packages $ChocolateyPackages
    }
    else {
        Write-InitLog 'Skipping package installation by request' 'WARN'
    }

    Assert-CommandExists -Name 'pwsh' -InstallHint 'Install PowerShell 7 or enable -InstallPackages.'

    Sync-Repository -Url $RepoUrl -Path $RepoRoot -SkipSync:$SkipClone -Pull:$ForcePull

    if ($ApplyConfig) {
        Invoke-SyncScriptApply -SyncScriptPath $ScriptPath -SyncConfigPath $ConfigPath -UseSkipGit $SkipGitDuringApply
    }
    else {
        Write-InitLog 'Skipping Apply step by request' 'WARN'
    }

    if ($RegisterScheduledTask) {
        Invoke-SyncScriptRegisterTask -SyncScriptPath $ScriptPath -SyncConfigPath $ConfigPath -DayOfMonth $ScheduledDayOfMonth -Time $ScheduledTime
    }
    else {
        Write-InitLog 'Scheduled task registration not requested'
    }

    Write-InitLog 'Workstation initialization complete'
}
catch {
    Write-InitLog $_.Exception.Message 'ERROR'
    throw
}
