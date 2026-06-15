---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# Export-ChocoMachineBackup

## SYNOPSIS
Exports Chocolatey package metadata to the backup repository.

## SYNTAX

```
Export-ChocoMachineBackup [[-RepoRoot] <String>] [[-ConfigRoot] <String>] [[-HostName] <String>]
 [[-RetentionCount] <Int32>] [-IncludeVersions] [-AllowOverwriteToday] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Uses Chocolatey's export feature to write a machine-specific manifest into the
backup repository config directory.
This manifest can be persisted in Git and
restored or reenforced on another workstation.

## EXAMPLES

### EXAMPLE 1
```
Export-ChocoMachineBackup
```

Exports Chocolatey state to the default backup repo config directory.

### EXAMPLE 2
```
Export-ChocoMachineBackup -RepoRoot 'C:\Dev\work\backup-repo' -IncludeVersions
```

Exports with package versions included to a specific backup repository.

## PARAMETERS

### -AllowOverwriteToday
Allow overwriting today's manifest file if it already exists.

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

### -ConfigRoot
Optional alternate root for the backup configuration files.
Defaults to
$RepoRoot\Config.

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

### -HostName
Host name used to name the machine-specific backup directory and manifest file.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-WorkstationIdentity).ComputerName
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeVersions
Include package version numbers in the exported Chocolatey manifest.

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
Root directory of the backup repository.
Defaults to the repo root resolved from
the module location.

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

### -RetentionCount
Number of previous Chocolatey manifests to retain.
Older manifests are deleted.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 5
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
- Requires Chocolatey installed and available in PATH.
- This command is safe with ShouldProcess and WhatIf support.

## RELATED LINKS
