<#
.SYNOPSIS
    Wrapper script to invoke the WorkstationBackup module backup workflow.

.DESCRIPTION
    Imports the WorkstationBackup module from the repository and delegates
    execution to the public Invoke-WorkstationBackup function. This script is
    intended for use by scheduled tasks or other script-based automation.

.EXAMPLE
    .\Invoke-WorkstationBackup.ps1

.EXAMPLE
    .\Invoke-WorkstationBackup.ps1 -RepoRoot 'C:\Dev\work\backup-repo' -SkipGit

.INPUTS
    None.

.OUTPUTS
    PSCustomObject
#>

$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$moduleManifest = Join-Path -Path $scriptRoot -ChildPath 'WorkstationBackup.psd1'
Import-Module -Name $moduleManifest -Force

Invoke-WorkstationBackup @args