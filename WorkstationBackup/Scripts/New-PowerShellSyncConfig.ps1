<#
.SYNOPSIS
    Wrapper script to create a new powershell-sync.config.json file using the module command.

.DESCRIPTION
    Imports the WorkstationBackup module and delegates config generation to
    New-PowerShellSyncConfig. Use this script to generate a backup repository config
    file from a plain PowerShell script entrypoint.

.EXAMPLE
    .\New-PowerShellSyncConfig.ps1

    Generates a new config file in the current backup repository.

.EXAMPLE
    .\New-PowerShellSyncConfig.ps1 -RepoRoot 'C:\Dev\work\backup-repo'

    Generates a new config file in a separate backup repository.

.INPUTS
    None.

.OUTPUTS
    PSCustomObject
#>
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$moduleManifest = Join-Path -Path $scriptRoot -ChildPath 'WorkstationBackup.psd1'
Import-Module -Name $moduleManifest -Force

New-PowerShellSyncConfig @args
