# WorkstationBackup refactor starter

This is the first pass of the refactor.

## What is already moved

- shared helper functions into `Private/`
- Chocolatey export into `Export-ChocoMachineBackup`
- workstation wrapper into `Invoke-WorkstationBackup`
- scheduled task registration into `Register-WorkstationBackupTask`

## What is intentionally still on a migration bridge

- the large PowerShell environment sync/apply logic still delegates to the original `Sync-PowerShellEnvironment.ps1`
- workstation initialization script still needs its clone/install logic migrated cleanly

## Important note about CLI scripts

The module exports functions from `Public/*.ps1`.

The runnable command-line wrappers live in `Scripts/`. They import the module and call the exported function with the same name.
