# WorkstationBackup Module

A PowerShell module for automating backup and restore of workstation configurations across machines, with support for syncing to a Git repository.

## Overview

**WorkstationBackup** provides a comprehensive solution for capturing and restoring your workstation's PowerShell environment, application settings, themes, and PowerShell Gallery modules. This enables reproducible workstation setups across multiple machines and provides version-controlled backups of your development environment.

### Supported Backup Types

- **PowerShell Profiles** - Current User and All Hosts profiles
- **Application Settings** - Custom application configuration files
- **Oh My Posh Themes** - PowerShell prompt themes
- **Windows Terminal Settings** - Terminal configuration and profile metadata
- **PowerShell Gallery Modules** - Installed modules with version pinning
- **Chocolatey Packages** - Machine-wide package inventory
- **Internal Modules** - Custom PowerShell modules

## Features

- 🔄 **Automated Syncing** - Export current state and Git synchronization
- 🎯 **Selective Restoration** - Restore specific components or all at once
- 📋 **Configuration-Driven** - JSON-based configuration for flexibility
- 🔐 **Smart Copying** - SHA256 hash-based comparison (only backs up changed files)
- ⚠️ **WhatIf Support** - Preview changes before applying
- 📝 **Detailed Logging** - Timestamped logs for debugging
- 🔄 **Version Pinned Modules** - PowerShell Gallery modules pinned to specific versions
- 🚀 **Task Scheduling** - Register automatic backup tasks (Windows)

## Requirements

- PowerShell 7.0 or later
- Windows 10/11 or Windows Server 2016+
- Git (for repository syncing, optional)
- Administrative privileges (for some operations like scheduled tasks)

## Installation

### From Source

```powershell
# Clone the repository
git clone https://github.com/mitch-j/WorkstationBackupModule.git
cd WorkstationBackupModule

# Import the module
Import-Module .\WorkstationBackup\WorkstationBackup.psd1
```

### Manual Setup

1. Download the module files
2. Place in `$PROFILE\..\Modules\WorkstationBackup\`
3. Run: `Import-Module WorkstationBackup`

## Quick Start

### 1. Configure Your Setup

Create or edit `powershell-sync.config.json` in your repository root:

```json
{
  "RepoRoot": "C:\\Dev\\work\\WorkstationBackup",
  "PersonalModulesPath": "Modules\\Personal",
  "ExternalModulesPath": "Modules\\External",
  "InventoryDirectory": "Inventory",
  "ProfilesDirectory": "Profiles",
  "SettingsDirectory": "Settings",
  "ThemesDirectory": "Themes",
  "FontsDirectory": "Fonts",
  "LogDirectory": "Logs",
  "PersonalModules": [],
  "DefaultRepository": "PSGallery"
}
```

### 2. Export Your Environment

```powershell
# Preview what will be backed up
Export-PowerShellEnvironment -WhatIf

# Actually export
Export-PowerShellEnvironment
```

### 3. Restore on Another Machine

```powershell
# Preview what will be restored
Import-PowerShellEnvironment -WhatIf

# Actually restore
Import-PowerShellEnvironment
```

### 4. Full Workstation Backup (Profiles + Packages)

```powershell
# Backup everything and sync to Git
Invoke-WorkstationBackup -WhatIf
Invoke-WorkstationBackup
```

## Configuration

### `powershell-sync.config.json` Schema

| Property              | Type   | Description                                             |
| :-------------------- | :----- | :------------------------------------------------------ |
| `RepoRoot`            | string | Root directory for backups (supports `$env:` variables) |
| `PersonalModulesPath` | string | Path for personal PowerShell modules                    |
| `ExternalModulesPath` | string | Path for external (PSGallery) modules                   |
| `InventoryDirectory`  | string | Path for JSON manifests                                 |
| `ProfilesDirectory`   | string | Path for PowerShell profiles                            |
| `SettingsDirectory`   | string | Path for application settings                           |
| `ThemesDirectory`     | string | Path for Oh My Posh themes                              |
| `FontsDirectory`      | string | Path for font files                                     |
| `LogDirectory`        | string | Path for operation logs                                 |
| `DefaultRepository`   | string | Default PowerShell Gallery (default: `PSGallery`)       |
| `Profiles`            | array  | Profile mappings (source → destination)                 |
| `SettingsFiles`       | array  | Settings file mappings                                  |
| `OhMyPosh`            | object | Oh My Posh backup settings                              |
| `Fonts`               | object | Nerd Fonts configuration                                |
| `WindowsTerminal`     | object | Windows Terminal backup settings                        |

### Example: Custom Settings Files

Add custom application settings to backup:

```json
{
  "SettingsFiles": [
    {
      "Source": "$env:APPDATA\\Code\\User\\settings.json",
      "Destination": "Settings\\vscode-settings.json"
    },
    {
      "Source": "$env:APPDATA\\.gitconfig",
      "Destination": "Settings\\.gitconfig"
    }
  ]
}
```

## Usage Examples

### Export Only PowerShell Profiles

```powershell
$config = Read-PowerShellSyncConfig -Path ".\powershell-sync.config.json"
Backup-PowerShellProfiles -Config $config
```

### Export PowerShell Gallery Modules

```powershell
$config = Read-PowerShellSyncConfig -Path ".\powershell-sync.config.json"
Export-PowerShellModules -Config $config
```

### Full Environment Export with Git Sync

```powershell
$config = Read-PowerShellSyncConfig -Path ".\powershell-sync.config.json"

# Export everything
Export-PowerShellEnvironment

# Note: Invoke-WorkstationBackup includes Git operations
Invoke-WorkstationBackup
```

### Restore Everything with Preview

```powershell
# See what will change
Import-PowerShellEnvironment -WhatIf

# Actually restore
Import-PowerShellEnvironment
```

## Public Functions

### Export Functions

- **`Export-PowerShellEnvironment`** - Export PowerShell profiles, settings, themes, and modules
- **`Export-ChocoMachineBackup`** - Export Chocolatey packages
- **`Export-InternalModuleBackup`** - Export custom PowerShell modules
- **`Invoke-WorkstationBackup`** - Complete workstation backup with Git sync

### Import Functions

- **`Import-PowerShellEnvironment`** - Restore PowerShell profiles, settings, themes, and modules
- **`Register-WorkstationBackupTask`** - Register scheduled task for automatic backups

## Private Functions (Advanced)

These functions are available for advanced usage:

- `Read-PowerShellSyncConfig` - Load JSON configuration
- `Backup-PowerShellProfiles` / `Restore-PowerShellProfiles`
- `Backup-SettingsFiles` / `Restore-SettingsFiles`
- `Backup-OhMyPoshThemes` / `Restore-OhMyPoshThemes`
- `Backup-WindowsTerminal` / `Restore-WindowsTerminal`
- `Export-PowerShellModules` / `Import-PowerShellModules`
- `Sync-PSModulePath` - Synchronize PSModulePath environment variable
- `Ensure-Directory` - Create directories with WhatIf support
- `Copy-IfDifferent` - Smart file copy using SHA256 comparison

## Architecture

```text
WorkstationBackup/
├── Private/              # Internal helper functions
│   ├── Backup-*.ps1     # Backup operations
│   ├── Restore-*.ps1    # Restore operations
│   ├── Export-*.ps1     # Export/inventory operations
│   └── *-Helper.ps1     # Utility functions
├── Public/              # User-facing functions
│   ├── Export-*.ps1
│   ├── Import-*.ps1
│   └── Invoke-*.ps1
├── Scripts/
│   ├── Legacy/          # Original scripts for reference
│   └── *.ps1            # CLI wrappers
├── WorkstationBackup.psd1   # Module manifest
└── WorkstationBackup.psm1   # Module loader
```

## Migration Status

This module has **completed migration** from a legacy script-based approach:

- ✅ Core backup/restore functionality migrated
- ✅ PowerShell profiles support
- ✅ Settings files support
- ✅ Oh My Posh themes support
- ✅ Windows Terminal support
- ✅ PowerShell Gallery modules support
- ✅ Nerd Fonts backup/restore support
- ✅ Machine state metadata
- ✅ Backward compatibility via legacy script fallback

### Migration Complete

The migration from `Sync-PowerShellEnvironment.ps1` to modular functions is now complete. All major features have been migrated:

- **Export Functions**: Profiles, settings, themes, fonts, modules, machine state
- **Import Functions**: Full restoration with dependency management
- **Configuration**: JSON-driven with template expansion
- **Error Handling**: Comprehensive logging and WhatIf support
- **Legacy Fallback**: `-UseLegacyScript` parameter for compatibility

The legacy script remains available for reference but is no longer required for normal operation.

## Git Integration

The module can automatically sync backups to a Git repository:

```powershell
# Full backup with Git operations
Invoke-WorkstationBackup

# Or export with Git sync
Export-PowerShellEnvironment
# Followed by manual Git operations as needed
```

## Logging

All operations generate timestamped logs:

```text
Logs/workstation-backup-2026-04.log

[2026-04-26 12:46:37] [INFO] Loaded config from C:\...\powershell-sync.config.json
[2026-04-26 12:46:37] [WARN] Profile source not found, skipping: C:\...
[2026-04-26 12:46:39] [INFO] Exported gallery module manifest with 5 entries.
```

Logs are written to the directory specified in `LogDirectory` config.

## Troubleshooting

### Profile Not Found

**Issue**: Warning about profile source not found

**Solution**: Ensure PowerShell profiles exist before backup:

```powershell
$PROFILE.CurrentUserCurrentHost  # Check paths
New-Item -Path $PROFILE.CurrentUserCurrentHost -Force  # Create if missing
```

### Config Not Found

**Issue**: "Config file not found"

**Solution**: Ensure `powershell-sync.config.json` is in the module root or repository root:

```powershell
$RepoRoot = Get-WorkstationBackupRoot
Get-ChildItem $RepoRoot -Filter "*.json"
```

### Modules Not Exporting

**Issue**: Gallery modules not backed up

**Solution**: Verify PowerShellGet availability:

```powershell
Get-InstalledModule | Measure-Object  # Check if modules exist
Get-Module PowerShellGet -ListAvailable  # Verify PowerShellGet is available
```

### Windows Terminal Settings Not Copying

**Issue**: Settings file at expected path but not backed up

**Solution**: Check Windows Terminal installation path:

```powershell
Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*"
```

## Performance Tips

- **Large Module Sets**: Export runs faster on second calls (hash comparison)
- **Network Shares**: Local paths significantly faster than network paths
- **Git Operations**: Use shallow clones for faster initial setup
- **Scheduled Tasks**: Run backups off-peak to avoid resource contention

## Best Practices

1. **Commit to Git**: Use `Invoke-WorkstationBackup` to ensure Git sync
2. **Regular Backups**: Set up scheduled tasks for automatic backups
3. **Test Restoration**: Regularly test restore on test machines
4. **Monitor Logs**: Check logs for warnings and errors
5. **Version Control**: Keep `powershell-sync.config.json` in version control
6. **Exclude Sensitive Files**: Don't back up credentials or secrets

## Contributing

Contributions welcome! Areas needing help:

- Nerd Fonts backup/restore implementation
- Cross-platform support (Linux/macOS)
- Additional application settings templates
- Performance optimizations
- Test coverage expansion

## License

[Add your license here]

## Support

For issues, questions, or feature requests:

1. Check [MIGRATION.md](MIGRATION.md) for migration status
2. Review [troubleshooting](#troubleshooting) section
3. Check logs in `LogDirectory`
4. Open an issue on GitHub

## Changelog

### v0.3.0 (Current - Migration Complete)

- ✨ **Migration Complete**: Fully migrated from legacy script to modular functions
- ✨ Added Nerd Fonts backup/restore support
- ✨ Added machine state metadata export
- ✨ Improved configuration handling with ConfigPath property
- ✨ Enhanced error handling and logging
- ✨ Added comprehensive WhatIf support throughout
- 🔧 Updated module version to 0.3.0
- �️ **Removed legacy compatibility**: Eliminated fallback to legacy scripts
- 🧹 **Cleanup**: Removed legacy wrapper scripts and deprecated functions

### v0.2.0 (Migration in Progress)

- ✨ Migrated core functionality from legacy script
- ✨ Added modular helper functions
- ✨ Improved logging and error handling
- ✨ Added WhatIf support throughout
- 🔧 Updated configuration schema
- 🔄 Backward compatibility with legacy script

### v0.1.0

- Initial public release

## See Also

- [MIGRATION.md](MIGRATION.md) - Detailed migration information
- [Tests/](Tests/) - Test suite
- `Get-Help Export-PowerShellEnvironment` - Built-in help
- `Get-Help Import-PowerShellEnvironment` - Built-in help
