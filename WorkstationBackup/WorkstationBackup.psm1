Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = $PSScriptRoot

$privateFiles = @(
    'Private\Resolve-TemplateValue.ps1'
    'Private\Ensure-Directory.ps1'
    'Private\Copy-IfDifferent.ps1'
    'Private\Write-BackupLog.ps1'
    'Private\Read-PowerShellSyncConfig.ps1'
    'Private\Set-BackupUserEnvironmentVariable.ps1'
    'Private\Get-WorkstationBackupRoot.ps1'
    'Private\Get-WorkstationIdentity.ps1'
    'Private\New-BackupFileName.ps1'
    'Private\Resolve-BackupPath.ps1'
    'Private\Remove-OldBackups.ps1'
    'Private\Test-RequiredCommand.ps1'

    'Private\Ensure-ModuleAvailable.ps1'
    'Private\Sync-PSModulePath.ps1'
    'Private\Initialize-ConfigDirectories.ps1'

    'Private\Get-NerdFontStyleSuffixPattern.ps1'
    'Private\Convert-InstalledFontNameToNerdFontCandidate.ps1'
    'Private\Get-NerdFontCandidatesFromLegacyConfig.ps1'
    'Private\Get-DesiredNerdFontFamilies.ps1'
    'Private\Get-InstalledNerdFontFamilies.ps1'
    'Private\Get-AvailableNerdFonts.ps1'
    'Private\Install-NerdFontPackage.ps1'
    'Private\Update-ConfigFontsFromDiscovery.ps1'
    'Private\Initialize-FontRestorePrerequisites.ps1'
    'Private\Export-NerdFonts.ps1'
    'Private\Restore-NerdFonts.ps1'

    'Private\Backup-PowerShellProfiles.ps1'
    'Private\Backup-SettingsFiles.ps1'
    'Private\Backup-OhMyPoshThemes.ps1'
    'Private\Backup-WindowsTerminal.ps1'
    'Private\Restore-PowerShellProfiles.ps1'
    'Private\Restore-SettingsFiles.ps1'
    'Private\Restore-OhMyPoshThemes.ps1'
    'Private\Restore-WindowsTerminal.ps1'

    'Private\Get-InstalledGalleryModuleRecords.ps1'
    'Private\Export-PowerShellModules.ps1'
    'Private\Import-PowerShellModules.ps1'

    'Private\Export-MachineState.ps1'
    'Private\Invoke-BackupGitSync.ps1'

    'Private\Invoke-ExportPowerShellEnvironment.ps1'
    'Private\Invoke-ApplyPowerShellEnvironment.ps1'
)

foreach ($relativePath in $privateFiles) {
    $fullPath = Join-Path -Path $script:ModuleRoot -ChildPath $relativePath

    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Required module file not found: $relativePath"
    }

    try {
        . $fullPath
    }
    catch {
        throw "Failed loading '$relativePath' from '$fullPath': $($_.Exception.Message)"
    }
}

$publicFiles = @(
    'Public\Export-ChocoMachineBackup.ps1'
    'Public\Export-InternalModuleBackup.ps1'
    'Public\Export-PowerShellEnvironment.ps1'
    'Public\Import-PowerShellEnvironment.ps1'
    'Public\Invoke-WorkstationBackup.ps1'
    'Public\Register-WorkstationBackupTask.ps1'
)

foreach ($relativePath in $publicFiles) {
    $fullPath = Join-Path -Path $script:ModuleRoot -ChildPath $relativePath

    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Required module file not found: $relativePath"
    }

    try {
        . $fullPath
    }
    catch {
        throw "Failed loading '$relativePath' from '$fullPath': $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Export-ChocoMachineBackup',
    'Export-InternalModuleBackup',
    'Export-PowerShellEnvironment',
    'Import-PowerShellEnvironment',
    'Invoke-WorkstationBackup',
    'Register-WorkstationBackupTask'
)