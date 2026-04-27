@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'WorkstationBackup.psm1'

    # Version number of this module.
    ModuleVersion        = '0.3.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core')

    # ID used to uniquely identify this module
    GUID                 = '6b2b8df1-5dc3-4a7f-89d7-6d88b65d8e61'

    # Author of this module
    Author               = 'Mitch Jurisch'

    # Company or vendor of this module
    CompanyName          = 'doitbestcorp'

    # Copyright statement for this module
    Copyright            = '(c) Mitch Jurisch. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Automates backup and restore of workstation PowerShell environment, settings, themes, modules, fonts, and related workstation state.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies   = @()

    # Script files (.ps1) that are run in the caller''s environment prior to importing this module.
    ScriptsToProcess     = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess       = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess     = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules        = @()

    # Functions to export from this module
    FunctionsToExport    = @(
        'Export-ChocoMachineBackup'
        'Export-InternalModuleBackup'
        'Export-PowerShellEnvironment'
        'Import-PowerShellEnvironment'
        'Invoke-WorkstationBackup'
        'Register-WorkstationBackupTask'
    )

    # Cmdlets to export from this module
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @()

    # List of all modules packaged with this module
    ModuleList           = @()

    # List of all files packaged with this module
    FileList             = @(
        'WorkstationBackup.psd1'
        'WorkstationBackup.psm1'
        'Public\Export-ChocoMachineBackup.ps1'
        'Public\Export-InternalModuleBackup.ps1'
        'Public\Export-PowerShellEnvironment.ps1'
        'Public\Import-PowerShellEnvironment.ps1'
        'Public\Invoke-WorkstationBackup.ps1'
        'Public\Register-WorkstationBackupTask.ps1'
        'Private\Backup-OhMyPoshThemes.ps1'
        'Private\Backup-PowerShellProfiles.ps1'
        'Private\Backup-SettingsFiles.ps1'
        'Private\Backup-WindowsTerminal.ps1'
        'Private\Convert-InstalledFontNameToNerdFontCandidate.ps1'
        'Private\Copy-IfDifferent.ps1'
        'Private\Ensure-Directory.ps1'
        'Private\Ensure-ModuleAvailable.ps1'
        'Private\Export-MachineState.ps1'
        'Private\Export-NerdFonts.ps1'
        'Private\Export-PowerShellModules.ps1'
        'Private\Get-AvailableNerdFonts.ps1'
        'Private\Get-DesiredNerdFontFamilies.ps1'
        'Private\Get-InstalledGalleryModuleRecords.ps1'
        'Private\Get-InstalledNerdFontFamilies.ps1'
        'Private\Get-NerdFontStyleSuffixPattern.ps1'
        'Private\Get-WorkstationBackupRoot.ps1'
        'Private\Get-WorkstationIdentity.ps1'
        'Private\Import-PowerShellModules.ps1'
        'Private\Initialize-ConfigDirectories.ps1'
        'Private\Initialize-FontRestorePrerequisites.ps1'
        'Private\Install-NerdFontPackage.ps1'
        'Private\Invoke-ApplyPowerShellEnvironment.ps1'
        'Private\Invoke-BackupGitSync.ps1'
        'Private\Invoke-ExportPowerShellEnvironment.ps1'
        'Private\New-BackupFileName.ps1'
        'Private\Read-PowerShellSyncConfig.ps1'
        'Private\Remove-OldBackups.ps1'
        'Private\Resolve-BackupPath.ps1'
        'Private\Resolve-TemplateValue.ps1'
        'Private\Restore-OhMyPoshThemes.ps1'
        'Private\Restore-NerdFonts.ps1'
        'Private\Restore-PowerShellProfiles.ps1'
        'Private\Restore-SettingsFiles.ps1'
        'Private\Restore-WindowsTerminal.ps1'
        'Private\Set-BackupUserEnvironmentVariable.ps1'
        'Private\Sync-PSModulePath.ps1'
        'Private\Test-RequiredCommand.ps1'
        'Private\Update-ConfigFontsFromDiscovery.ps1'
        'Private\Write-BackupLog.ps1'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData          = @{
        PSData = @{
            Tags         = @(
                'PowerShell'
                'Backup'
                'Restore'
                'Workstation'
                'Profiles'
                'WindowsTerminal'
                'OhMyPosh'
                'NerdFonts'
            )

            LicenseUri   = ''
            ProjectUri   = ''
            IconUri      = ''
            ReleaseNotes = @'
0.3.0
- Added export/apply orchestration helpers for module-based environment sync
- Added Nerd Fonts export/restore helper pipeline
- Added machine-state export helper
- Added PS_CONFIG_ROOT environment variable helper
- Updated module structure to support full migrated workflow
'@
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI          = ''

    # Default prefix for commands exported from this module
    DefaultCommandPrefix = ''
}