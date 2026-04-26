[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepoRoot,

    [Parameter()]
    [string]$TaskName = 'WorkstationBackup',

    [Parameter()]
    [ValidateRange(1, 28)]
    [int]$ScheduledDayOfMonth = 1,

    [Parameter()]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$ScheduledTime = '09:00',

    [Parameter()]
    [string]$PwshPath = 'pwsh.exe',

    [Parameter()]
    [switch]$SkipGit,

    [Parameter()]
    [switch]$SkipPowerShellBackup,

    [Parameter()]
    [switch]$SkipChocoBackup
)

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $moduleRoot 'WorkstationBackup.psd1') -Force

Register-WorkstationBackupTask @PSBoundParameters
