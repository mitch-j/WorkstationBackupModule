# Workstation Restore Workflow

This document describes the restore workflow for the WorkstationBackup module.
It is scoped to recovering a PowerShell environment from an existing backup repository and configuration file.

## Overview

The recommended restore workflow is:

1. Install or place the module in a PowerShell module path.
2. Obtain or clone the backup repository that contains `powershell-sync.config.json`.
3. Confirm the repository root and configuration file location.
4. Run `Import-PowerShellEnvironment` to restore the environment.
5. Verify restored profiles, settings, themes, fonts, and modules.

## Prerequisites

- PowerShell 7.0 or later.
- A backup repository with `powershell-sync.config.json` already created.
- The repository should contain the exported backup assets from a prior backup run.
- Font installations may require administrator privileges.
- If you restore from a remote clone, ensure the repository is checked out to the desired backup commit.

## Step 1: Install the module

Place the `WorkstationBackup` module under a module path such as:

- `C:\Users\<User>\Documents\PowerShell\Modules\WorkstationBackup\`
- or `C:\Program Files\PowerShell\Modules\WorkstationBackup\`

Then import it:

```powershell
Import-Module WorkstationBackup
```

You can also import it directly from the repo root:

```powershell
Import-Module 'C:\Dev\work\PowershellModules\WorkstationBackupModule\WorkstationBackup\WorkstationBackup.psd1'
```

## Step 2: Acquire the backup repository

If you already have the repository locally, use that folder as the restore source.
If you are restoring on a different machine, clone the remote backup repository:

```powershell
git clone https://example.com/your/repo.git C:\Backup\Workstation
```

The restore process expects `powershell-sync.config.json` in the repository root by default.

## Step 3: Confirm the config file path

By default, `Import-PowerShellEnvironment` will use:

- `C:\Backup\Workstation\powershell-sync.config.json`

If your config file is in a different location, pass `-ConfigPath` explicitly:

```powershell
Import-PowerShellEnvironment -ConfigPath 'C:\Backup\Workstation\powershell-sync.config.json'
```

If you do not pass `-RepoRoot`, the command attempts to determine the repository root automatically from the module location.

## Step 4: Run the restore

Preview the restore operation first:

```powershell
Import-PowerShellEnvironment -WhatIf
```

Then perform the restore:

```powershell
Import-PowerShellEnvironment
```

If you want to continue past font installation failures, use:

```powershell
Import-PowerShellEnvironment -SkipFontInstallFailures
```

### What this does

`Import-PowerShellEnvironment` performs:

- Restoration of PowerShell profiles and profile mappings
- Restoration of application settings files
- Restoration of Oh My Posh themes
- Restoration of Windows Terminal settings
- Restoration of PowerShell Gallery modules from backup inventory
- Optional Nerd Font installation when configured

## Step 5: Verify restore results

After completion, verify that:

- PowerShell profiles are present in the expected locations.
- Settings files have been restored correctly.
- Oh My Posh themes are available.
- Windows Terminal configuration is restored.
- PowerShell modules are installed to the configured `ExternalModulesPath`.
- Fonts are installed if that restore path is configured.

## Important notes

- This document is restore-only; it does not cover backup repository initialization or scheduled backups.
- `Import-PowerShellEnvironment` requires a valid `powershell-sync.config.json` file.
- If the config file is outside the repo root, always pass `-ConfigPath`.
- The restore process will create necessary directories before restoring files.
- `-SkipFontInstallFailures` is useful when font installation is not required or is failing on the target machine.
- If the backup repository is not checked out to the desired commit, restore may use incorrect backup data.

## Troubleshooting

- If the command fails because the config file is missing, verify the path and use `-ConfigPath`.
- If font installation fails, use `-SkipFontInstallFailures` and restore the fonts separately later.
- If module installation fails, check network access to PowerShell Gallery or the configured repository source.
- If the restore path is incorrect, verify the resolved paths in `powershell-sync.config.json`.

## Related files

- `WorkstationBackup/Public/Import-PowerShellEnvironment.ps1`
- `WorkstationBackup/Private/Invoke-ApplyPowerShellEnvironment.ps1`
- `WorkstationBackup/Private/Restore-VSCode.ps1`
- `powershell-sync.config.json`
