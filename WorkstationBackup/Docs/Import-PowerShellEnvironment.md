---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# Import-PowerShellEnvironment

## SYNOPSIS
Restores the PowerShell environment from a backup repository.

## SYNTAX

```
Import-PowerShellEnvironment [[-RepoRoot] <String>] [[-ConfigPath] <String>] [-SkipFontInstallFailures]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Restores a workstation's PowerShell configuration from a backup repository,
including profiles, settings files, Oh My Posh themes, Windows Terminal settings,
and PowerShell Gallery modules.

## EXAMPLES

### EXAMPLE 1
```
Import-PowerShellEnvironment
```

Restores the environment from default locations using modular functions.

### EXAMPLE 2
```
Import-PowerShellEnvironment -WhatIf
```

Shows what would be restored without making changes.

### EXAMPLE 3
```
Import-PowerShellEnvironment -RepoRoot 'C:\Backup\MyEnvironment'
```

Restores from a custom repository location.

### EXAMPLE 4
```
Import-PowerShellEnvironment -SkipFontInstallFailures
```

Restores environment but continues even if font installation fails.

## PARAMETERS

### -ConfigPath
Path to the powershell-sync.config.json configuration file.
If not provided,
defaults to $RepoRoot/powershell-sync.config.json.
This file is the primary
source of restore path configuration and is required for the import operation.

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

### -SkipFontInstallFailures
If specified, continues restoration even if Nerd Font installation fails.
Without this switch, font installation errors halt the process.

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
- Creates necessary directories before restoring files
- All operations support WhatIf for safe preview
- Font installations may require administrator privileges
- PowerShell modules are installed to ExternalModulesPath from config

## RELATED LINKS

[Export-PowerShellEnvironment
Invoke-WorkstationBackup]()

