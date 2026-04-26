@{
    RootModule        = 'WorkstationBackup.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'cf7a7f1f-a6c1-43d3-b8a9-b4ef5370b194'
    Author            = 'Mitch Jurisch'
    CompanyName       = 'Personal'
    Copyright         = '(c) Mitch Jurisch. All rights reserved.'
    Description       = 'Internal workstation backup helpers and task functions.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Invoke-WorkstationBackup',
        'Export-PowerShellEnvironment',
        'Import-PowerShellEnvironment',
        'Export-ChocoMachineBackup',
        'Register-WorkstationBackupTask'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('backup', 'workstation', 'powershell', 'chocolatey')
            ProjectUri = 'https://example.invalid/local-only'
        }
    }
}
