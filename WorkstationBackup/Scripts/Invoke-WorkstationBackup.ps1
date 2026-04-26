[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepoRoot,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$LegacyPowerShellScriptPath,

    [Parameter()]
    [switch]$SkipPowerShellBackup,

    [Parameter()]
    [switch]$SkipChocoBackup,

    [Parameter()]
    [switch]$SkipGit,

    [Parameter()]
    [switch]$SkipPull,

    [Parameter()]
    [switch]$SkipPush,

    [Parameter()]
    [string]$CommitMessage,

    [Parameter()]
    [string[]]$ChocoBackupArguments = @()
)

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $moduleRoot 'WorkstationBackup.psd1') -Force

Invoke-WorkstationBackup @PSBoundParameters
