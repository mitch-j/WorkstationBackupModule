---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# Register-WorkstationBackupTask

## SYNOPSIS
Registers a Windows scheduled task to run workstation backups.

## SYNTAX

```
Register-WorkstationBackupTask [[-RepoRoot] <String>] [[-TaskName] <String>] [[-ScheduledDayOfMonth] <Int32>]
 [[-ScheduledTime] <String>] [[-PwshPath] <String>] [-SkipGit] [-SkipPowerShellBackup] [-SkipChocoBackup]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a Windows Scheduled Task that invokes the public backup wrapper script
with the configured backup repository root.
This allows periodic, unattended
backup execution using the module's standard workflow.

## EXAMPLES

### EXAMPLE 1
```
Register-WorkstationBackupTask -RepoRoot 'C:\Dev\work\backup-repo' -ScheduledDayOfMonth 1 -ScheduledTime '02:00'
```

Registers a monthly backup task for the backup repo.

## PARAMETERS

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

### -PwshPath
Path to the PowerShell executable used by the scheduled task.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Pwsh.exe
Accept pipeline input: False
Accept wildcard characters: False
```

### -RepoRoot
Root directory of the backup repository.
If not specified, the repository root is
resolved from the module location.

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

### -ScheduledDayOfMonth
Day of month on which the monthly backup task runs.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScheduledTime
Time of day when the task should execute, in HH:mm format.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 09:00
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipChocoBackup
Skip the Chocolatey package backup stage when the task runs.

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

### -SkipGit
Skip Git sync when the scheduled backup runs.

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

### -SkipPowerShellBackup
Skip the PowerShell environment backup stage when the task runs.

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

### -TaskName
Name of the scheduled task to register.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: WorkstationBackup
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

### None.
## NOTES
- Only supported on Windows.
- The task runs the wrapper script at \`$RepoRoot\Scripts\Invoke-WorkstationBackup.ps1\`.
- The scheduled task is created with Highest run level and Interactive logon type.

## RELATED LINKS
