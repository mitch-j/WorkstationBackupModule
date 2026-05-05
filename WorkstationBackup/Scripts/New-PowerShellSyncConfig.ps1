$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$moduleManifest = Join-Path -Path $scriptRoot -ChildPath 'WorkstationBackup.psd1'
Import-Module -Name $moduleManifest -Force

New-PowerShellSyncConfig @args
