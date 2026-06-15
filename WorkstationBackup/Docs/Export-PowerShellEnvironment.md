---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# Export-PowerShellEnvironment

## SYNOPSIS
Exports the current PowerShell environment to a backup repository.

## SYNTAX

```
Export-PowerShellEnvironment [[-RepoRoot] <String>] [[-ConfigPath] <String>]
 [[-InternalModulesSourceRoot] <String>] [[-InternalModulesBackupRoot] <String>]
 [[-ExcludeInternalModules] <String[]>] [-WriteInternalModuleManifest] [-UpdateFontConfigFromDiscovery]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Exports the current workstation's PowerShell configuration including profiles,
settings files, Oh My Posh themes, Windows Terminal settings, and PowerShell
Gallery modules to a backup repository for version control and restoration.

## EXAMPLES

### EXAMPLE 1
```
Export-PowerShellEnvironment
```

Exports the current environment using the modular functions with defaults.

### EXAMPLE 2
```
Export-PowerShellEnvironment -WhatIf
```

Shows what would be exported without making changes.

### EXAMPLE 3
```
Export-PowerShellEnvironment -RepoRoot 'C:\Backup\MyEnvironment'
```

Exports to a custom repository location.

### EXAMPLE 4
```
Export-PowerShellEnvironment `
    -InternalModulesSourceRoot 'C:\Modules\MyModules' `
    -InternalModulesBackupRoot 'Modules\Internal' `
    -WriteInternalModuleManifest
```

Exports environment and also backs up custom modules with a manifest.

## PARAMETERS

### -ConfigPath
Path to the powershell-sync.config.json configuration file.
If not provided,
defaults to $RepoRoot/powershell-sync.config.json.
This file is the primary
source of backup path configuration and is required for the export operation.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeInternalModules
Array of module names to exclude from internal module backup.
Example: @('Test-Module', 'Dev-Module')

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -InternalModulesBackupRoot
Destination directory in the repository for internal module backups.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InternalModulesSourceRoot
Source directory for custom PowerShell modules to back up.
When specified
along with InternalModulesBackupRoot, internal modules are also exported.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RepoRoot
The root directory of the backup repository.
If not provided, automatically
determined from the module's location.
Supports $env: variable expansion.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateFontConfigFromDiscovery
{{ Fill UpdateFontConfigFromDiscovery Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WriteInternalModuleManifest
If specified, writes a manifest JSON file listing all backed up internal modules.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input not supported.
## OUTPUTS

### None. Outputs messages to the console and logs.
## NOTES
- Requires PowerShell 7.0 or later
- Uses SHA256 hash comparison to avoid unnecessary file copies
- All operations support WhatIf for safe preview
- Logs all operations to the configured LogDirectory

## RELATED LINKS

[Import-PowerShellEnvironment
Invoke-WorkstationBackup]()

