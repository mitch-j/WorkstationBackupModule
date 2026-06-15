---
external help file: WorkstationBackup-help.xml
Module Name: WorkstationBackup
online version:
schema: 2.0.0
---

# Invoke-WorkstationBackup

## SYNOPSIS
Orchestrates a full workstation backup with optional Git synchronization.

## SYNTAX

```
Invoke-WorkstationBackup [[-RepoRoot] <String>] [[-ConfigPath] <String>] [-SkipPowerShellBackup]
 [-SkipChocoBackup] [-SkipGit] [-SkipPull] [-SkipPush] [[-CommitMessage] <String>] [-AllowOverwriteToday]
 [-IncludeVersions] [[-RetentionCount] <Int32>] [[-InternalModulesSourceRoot] <String>]
 [[-InternalModulesBackupRoot] <String>] [[-ExcludeInternalModules] <String[]>] [-WriteInternalModuleManifest]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Runs PowerShell environment export, Chocolatey export, and optional Git sync in a
single command.
The command uses the JSON configuration file as the primary source
of path and repository information when \`-ConfigPath\` is supplied.

## EXAMPLES

### EXAMPLE 1
```
Invoke-WorkstationBackup
```

Runs all backup stages and synchronizes changes to Git using the default repo root.

### EXAMPLE 2
```
Invoke-WorkstationBackup -ConfigPath 'C:\Dev\work\backup-repo\powershell-sync.config.json'
```

Uses an external config file and backup repository.

### EXAMPLE 3
```
Invoke-WorkstationBackup -SkipChocoBackup -WhatIf
```

Previews a PowerShell-only backup without Chocolatey export.

## PARAMETERS

### -AllowOverwriteToday
Allow Chocolatey export to overwrite today's manifest if it already exists.

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

### -CommitMessage
Custom commit message for the Git sync stage.

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

### -ConfigPath
Path to the powershell-sync.config.json file.
When supplied without \`-RepoRoot\`, the
repository root is derived from the configuration file.

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
List of module names to exclude from internal module backup.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeVersions
Include package version information in the Chocolatey export manifest.

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

### -InternalModulesBackupRoot
Destination directory inside the backup repo for internal modules.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InternalModulesSourceRoot
Source directory for custom internal PowerShell modules.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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
If omitted, it is resolved from the
module root or the configuration file when \`-ConfigPath\` is provided.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: C:\Dev\work\WorkstationBackup
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetentionCount
Number of Chocolatey export manifests to retain.
Older exports are automatically removed.

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipChocoBackup
Skip the Chocolatey package export stage.

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
Skip Git commit/push/pull synchronization.

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
Skip the PowerShell environment export stage.

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

### -SkipPull
Skip git pull before pushing changes.

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

### -SkipPush
Skip git push after committing changes.

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
If specified, writes a manifest JSON file listing backed up internal modules.

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
- This command is the preferred entrypoint for full workstation backup workflows.
- \`Export-PowerShellEnvironment\` does not perform Git synchronization itself; Git sync is handled by this wrapper.
- If no backup stages are selected, the command logs a warning and exits.

## RELATED LINKS
