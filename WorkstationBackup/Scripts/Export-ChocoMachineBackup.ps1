[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepoRoot,

    [Parameter()]
    [string]$ConfigRoot,

    [Parameter()]
    [string]$HostName = $env:COMPUTERNAME,

    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$RetentionCount = 5,

    [Parameter()]
    [switch]$IncludeVersions,

    [Parameter()]
    [switch]$AllowOverwriteToday
)

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $moduleRoot 'WorkstationBackup.psd1') -Force

Export-ChocoMachineBackup @PSBoundParameters
