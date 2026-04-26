[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepoRoot,

    [Parameter()]
    [string]$LegacyScriptPath,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [switch]$SkipGit,

    [Parameter()]
    [switch]$UpdateFontConfigFromDiscovery,

    [Parameter()]
    [switch]$SkipFontInstallFailures
)

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path $moduleRoot 'WorkstationBackup.psd1') -Force

Export-PowerShellEnvironment @PSBoundParameters
