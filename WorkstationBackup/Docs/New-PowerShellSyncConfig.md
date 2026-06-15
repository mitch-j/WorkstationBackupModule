---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# New-PowerShellSyncConfig

## SYNOPSIS
Creates or updates the powershell-sync.config.json configuration file for a backup repository.

## SYNTAX

```
New-PowerShellSyncConfig [[-RepoRoot] <String>] [[-ConfigPath] <String>] [-Force] [-UseDefaults]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Generates the JSON configuration file that defines backup paths, profile mappings,
theme and terminal settings, font restore targets, and module directories.
This command is the recommended first step when setting up a new backup repo or
onboarding a new workstation.

## EXAMPLES

### EXAMPLE 1
```
New-PowerShellSyncConfig
```

Generates a new config file in the current repository root.

### EXAMPLE 2
```
New-PowerShellSyncConfig -RepoRoot 'C:\Dev\work\backup-repo'
```

Creates the config file in a separate backup repository.

### EXAMPLE 3
```
New-PowerShellSyncConfig -ConfigPath 'C:\Dev\work\backup-repo\powershell-sync.config.json' -Force
```

Writes the config file to a custom location and overwrites any existing file.

## PARAMETERS

### -ConfigPath
The path to write the configuration file.
Defaults to '$RepoRoot\powershell-sync.config.json'.

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

### -Force
Overwrite an existing configuration file.

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
If omitted, the module root is used as
a starting point and the user is prompted to confirm the location.

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

### -UseDefaults
Generate the config file without prompting for values.

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

### None.
## OUTPUTS

### PSCustomObject
## NOTES
- Keep the config file under version control in your backup repository.
- The generated config file uses template expansion for environment variables and profile paths.
- Use this command before running Export-PowerShellEnvironment or Import-PowerShellEnvironment.

## RELATED LINKS
