---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# Export-InternalModuleBackup

## SYNOPSIS
Packages internal PowerShell modules into archive files for backup.

## SYNTAX

```
Export-InternalModuleBackup [-SourceRoot] <String> [-DestinationRoot] <String> [[-IncludeModules] <String[]>]
 [[-ExcludeModules] <String[]>] [-WriteManifest] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Compresses each folder in the internal module source root into a ZIP archive
and writes the results into the specified destination root.
Optionally writes
a manifest describing the archived modules.

## EXAMPLES

### EXAMPLE 1
```
Export-InternalModuleBackup -SourceRoot 'C:\Modules\Internal' -DestinationRoot 'C:\Backup\Modules'
```

Archives all internal modules into the backup repository.

### EXAMPLE 2
```
Export-InternalModuleBackup -SourceRoot 'C:\Modules\Internal' -DestinationRoot 'C:\Backup\Modules' -ExcludeModules @('TempModule') -WriteManifest
```

Archives internal modules while excluding a specific module and writes a manifest.

## PARAMETERS

### -DestinationRoot
Directory where module archives will be written.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeModules
Specific module names to exclude from the backup.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeModules
Specific module names to include in the backup.
If empty, all modules are included.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @()
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

### -SourceRoot
Directory containing the internal modules to back up.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WriteManifest
Write a JSON manifest file listing archived internal modules.

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

### System.Object[]
## NOTES
- This command uses Compress-Archive and requires Windows PowerShell compression support.
- If an archive already exists, it is replaced when the command runs.

## RELATED LINKS
