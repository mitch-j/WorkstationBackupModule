# Workstation Backup Workflow

This document describes the intended setup and backup workflow for the WorkstationBackup module on a new machine.
It covers the exact sequence you described, plus the relevant options and caveats.

## Overview

The recommended workflow is:

1. Install or place the module in a PowerShell module path.
2. Generate a repository configuration file with `New-PowerShellSyncConfig.ps1`.
3. Initialize a Git repository in the backup repository root and configure a remote.
4. Run `Invoke-WorkstationBackup` to perform backups and Git sync.
5. Register a scheduled task with `Register-WorkstationBackupTask` for recurring backups.

## Prerequisites

- PowerShell 7.0 or later.
- Git installed and available on `PATH`.
- Windows if you want scheduled task registration.
- A target backup repository folder where `powershell-sync.config.json` and backup output will live.
- `WorkstationBackup.psd1` and `WorkstationBackup.psm1` must be present in the module root.

## Step 1: Install the module

Place the `WorkstationBackup` module under a module path such as:

- `C:\Users\<User>\Documents\PowerShell\Modules\WorkstationBackup\`
- or `C:\Program Files\PowerShell\Modules\WorkstationBackup\`

This allows you to import the module with:

```powershell
Import-Module WorkstationBackup
```

You can also import it directly from the repo root:

```powershell
Import-Module 'C:\Dev\work\PowershellModules\WorkstationBackupModule\WorkstationBackup\WorkstationBackup.psd1'
```

## Step 2: Initialize the backup repository and Git remote

Create the folder where backups will be stored and initialize Git there:

```powershell
New-Item -Path 'C:\Backup\Workstation' -ItemType Directory -Force
Set-Location 'C:\Backup\Workstation'
git init
git remote add origin https://example.com/your/repo.git
```

The repo root is the folder that will hold `powershell-sync.config.json` and the backup output.

## Step 3: Create the config file

Create the configuration file using the wrapper script:

```powershell
Set-Location 'C:\Backup\Workstation'
..\Workstation\Scripts\New-PowerShellSyncConfig.ps1
```

Or, if you are already in the repo root and the wrapper script is accessible:

```powershell
.
\Workstation\Scripts\New-PowerShellSyncConfig.ps1 -RepoRoot 'C:\Backup\Workstation'
```

This generates `powershell-sync.config.json` in the repository root and resolves paths for backup targets.

## Step 4: Run the backup

Run the public module function:

```powershell
Invoke-WorkstationBackup
```

If your config file lives in a separate folder or you are not in the repo root, pass `-ConfigPath`:

```powershell
Invoke-WorkstationBackup -ConfigPath 'C:\Backup\Workstation\powershell-sync.config.json'
```

### What this does

`Invoke-WorkstationBackup` performs:

- PowerShell environment export via `Export-PowerShellEnvironment`
- Chocolatey package export via `Export-ChocoMachineBackup`
- Git sync via `Invoke-BackupGitSync`

If the backup directory is not a Git repo, Git sync is skipped with a warning.

### Optional command arguments

- `-SkipGit` — perform backup without commit/push
- `-SkipChocoBackup` — skip Chocolatey export
- `-SkipPowerShellBackup` — skip the PowerShell environment backup stage
- `-CommitMessage` — customize the Git commit message
- `-AllowOverwriteToday` — allow Chocolatey manifest overwrite for today
- `-IncludeVersions` — include package versions in Chocolatey export
- `-RetentionCount` — keep only the most recent N Chocolatey manifests
- `-InternalModulesSourceRoot` / `-InternalModulesBackupRoot` — back up custom internal modules
- `-ExcludeInternalModules` — exclude specific module names when exporting internal modules
- `-WriteInternalModuleManifest` — write a manifest for archived internal modules

## Step 5: Commit and push

`Invoke-WorkstationBackup` runs Git operations if your repo is initialized:

- `git add .`
- `git commit -m '<generated message>'`
- `git pull` (unless `-SkipPull` is supplied)
- `git push` (unless `-SkipPush` is supplied)

This means you do not need to manually commit every backup, as long as Git is set up and the repo contains a valid remote.

## Step 6: Register the scheduled task

To automate monthly backups, register the scheduled task:

```powershell
Register-WorkstationBackupTask -RepoRoot 'C:\Backup\Workstation' -ScheduledDayOfMonth 1 -ScheduledTime '02:00'
```

This creates a Windows scheduled task that runs the wrapper script at:

- `C:\Backup\Workstation\Scripts\Invoke-WorkstationBackup.ps1`

The task uses `pwsh.exe` and the same backup workflow.

### Task options

- `-TaskName` — custom scheduled task name
- `-ScheduledDayOfMonth` — day of month to run
- `-ScheduledTime` — execution time in `HH:mm`
- `-PwshPath` — PowerShell executable path
- `-SkipGit` — disable Git sync for scheduled runs
- `-SkipPowerShellBackup` — skip the PowerShell environment export stage
- `-SkipChocoBackup` — skip Chocolatey export stage

## Why the wrapper script is useful

For interactive use, you can run the public function directly after importing the module.

The wrapper script is important for automated scheduled execution because it:

- imports the module reliably from the repository location
- provides a stable file path for scheduled task configuration
- accepts the same public arguments as the function

In this repo, the scheduled task registration currently expects the wrapper script at:

- `Scripts\Invoke-WorkstationBackup.ps1`

## Important caveats

- `Register-WorkstationBackupTask` currently works only on Windows.
- Scheduled backups rely on the wrapper script existing at `Scripts\Invoke-WorkstationBackup.ps1`.
- Git sync requires the repo to already be initialized and a remote configured.
- If the scheduled task runs as a different Windows user, Git credential access may differ.
- If your config file is outside the repo root, always pass `-ConfigPath` when running the function or script.
- The wrapper script uses `WorkstationBackup.psd1` from the repo root, so the script and module manifest must remain aligned.
- `Invoke-WorkstationBackup` will skip Git sync if `.git` is missing.
- For `New-PowerShellSyncConfig.ps1`, the repo root is the folder you want to use for backups, not necessarily the module source directory.

## Recommended flow summary

1. Install the module or ensure the module path is available.
2. Create the backup repo and configure Git.
3. Run `New-PowerShellSyncConfig.ps1` to generate `powershell-sync.config.json`.
4. Run `Invoke-WorkstationBackup` once to perform and sync the first backup.
5. Confirm backup output and Git push succeeded.
6. Register the scheduled task with `Register-WorkstationBackupTask`.
7. Periodically verify logs and restore behavior.

## Verification after setup

- Confirm `powershell-sync.config.json` exists in the repo root.
- Confirm `.git` exists and the remote is configured.
- Confirm `Scripts\Invoke-WorkstationBackup.ps1` exists.
- Confirm the scheduled task runs at the expected time.
- Confirm backup files appear under the configured repository paths.
- Confirm `git log` contains the backup commit.

## Troubleshooting notes

- If `Invoke-WorkstationBackup` reports `Skipping Git sync`, verify `.git` exists in `RepoRoot`.
- If `Register-WorkstationBackupTask` fails, verify `Register-ScheduledTask` is available and you are on Windows.
- If `New-PowerShellSyncConfig.ps1` fails, verify the module manifest path is correct relative to the script.
- If Git push fails on scheduled runs, verify credentials are available for the scheduled task user.

## Related files

- `WorkstationBackup/Scripts/New-PowerShellSyncConfig.ps1`
- `WorkstationBackup/Scripts/Invoke-WorkstationBackup.ps1`
- `WorkstationBackup/Public/Invoke-WorkstationBackup.ps1`
- `WorkstationBackup/Public/Register-WorkstationBackupTask.ps1`
- `powershell-sync.config.json`
