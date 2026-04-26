<#
.SYNOPSIS
Synchronizes a portable PowerShell environment between the local workstation and a backing repository.

.DESCRIPTION
Sync-PowerShellEnvironment.ps1 manages export, restore, and optional Git synchronization
for a PowerShell-centric workstation configuration repository.

The script is intended to make a PowerShell environment reproducible across machines by
capturing and restoring items such as:

- PowerShell profiles
- selected application settings files
- oh-my-posh themes
- Windows Terminal settings
- font inventory and optional Nerd Font installation
- PowerShell Gallery module inventory
- machine state metadata

The script supports four modes:

- Sync
  Runs Apply, then Export, then optional Git synchronization.
- Apply
  Restores the local environment from the repository.
- Export
  Captures the current local environment into the repository.
- RegisterScheduledTask
  Registers a monthly scheduled task that runs the script in Sync mode.

Git operations are disabled by default and are only performed when -EnableGitSync is specified.

.PARAMETER Mode
Operation mode for the script.

Valid values:
- Sync
- Apply
- Export
- RegisterScheduledTask

Default:
Sync

.PARAMETER ConfigPath
Path to the JSON configuration file that defines repository paths, profile mappings,
settings file mappings, theme settings, font settings, and related options.

Default:
C:\Dev\work\ps-config-work\powershell-sync.config.json

.PARAMETER EnableGitSync
Enables Git operations for the current run.

When specified, the script may perform pull, add, commit, and push operations depending
on the selected mode and the other Git-related switches.

.PARAMETER SkipGit
Skips all Git operations, even when -EnableGitSync is specified.

.PARAMETER SkipPull
Skips the initial Git pull step during synchronization.

Relevant only when Git sync is enabled.

.PARAMETER SkipPush
Skips the final Git push step during synchronization.

Relevant only when Git sync is enabled.

.PARAMETER PruneExternalModules
Indicates intent to prune untracked external module versions.

Current behavior:
The script logs a warning that automatic pruning is not implemented.

.PARAMETER WhatIf
Shows what the script would do without making changes where supported.

This affects file operations, environment changes, scheduled task registration,
and Git command execution logging.

.PARAMETER ScheduledDayOfMonth
Day of the month to use when registering the scheduled task.

Default:
1

.PARAMETER ScheduledTime
Time of day to use when registering the scheduled task, in 24-hour HH:mm format.

Default:
09:00

.PARAMETER UpdateFontConfigFromDiscovery
Updates the configured font list in the JSON configuration based on discovered installed fonts.

This is useful when you want to promote discovered Nerd Font families into the config.

.PARAMETER SkipFontInstallFailures
Continues processing when individual Nerd Font installations fail during Apply.

Without this switch, font installation failures may stop the run.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1

Runs the script in Sync mode using the default config path.
This applies configuration from the repo, exports the current workstation state back
to the repo, and performs Git sync only if -EnableGitSync is also specified.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode Apply

Restores the local PowerShell environment from the repository without exporting changes.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode Export -ConfigPath .\powershell-sync.config.json

Exports the current workstation state into the repository using the specified config file.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode Sync -EnableGitSync

Runs Apply, then Export, then performs Git pull/add/commit/push operations as needed.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode Sync -EnableGitSync -SkipPush

Runs synchronization with Git enabled, but does not push changes to the remote.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode Apply -SkipFontInstallFailures

Restores the environment and continues even if one or more Nerd Font installations fail.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode Export -UpdateFontConfigFromDiscovery

Exports current environment state and updates the configured font list based on discovered fonts.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Sync-PowerShellEnvironment.ps1 -Mode RegisterScheduledTask -ScheduledDayOfMonth 1 -ScheduledTime 09:00

Registers a monthly scheduled task that runs the script in Sync mode on the first day
of each month at 09:00.

.NOTES
This script requires PowerShell 7 or later.

The configuration file controls which profiles, settings files, themes, fonts, and
repository paths are used. Review the JSON config before first use.

Git synchronization is opt-in. Use -EnableGitSync to allow repository pull/commit/push behavior.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('Sync','Apply','Export','RegisterScheduledTask')]
    [string]$Mode = 'Sync',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigPath = (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'powershell-sync.config.json'),

    [Parameter()]
    [switch]$EnableGitSync,

    [Parameter()]
    [switch]$SkipGit,

    [Parameter()]
    [switch]$SkipPull,

    [Parameter()]
    [switch]$SkipPush,

    [Parameter()]
    [switch]$PruneExternalModules,

    [Parameter()]
    [ValidateRange(1, 28)]
    [int]$ScheduledDayOfMonth = 1,

    [Parameter()]
    [ValidateScript({
        $parsed = [datetime]::MinValue
        [datetime]::TryParseExact(
            $_,
            'HH:mm',
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None,
            [ref]$parsed
        )
    })]
    [string]$ScheduledTime = '09:00',

    [Parameter()]
    [switch]$UpdateFontConfigFromDiscovery,

    [Parameter()]
    [switch]$SkipFontInstallFailures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:GitEnabled = $EnableGitSync -and (-not $SkipGit)

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message
    Write-Host $line

    if ($script:Config -and $script:Config.LogDirectory) {
        if (-not (Test-Path -LiteralPath $script:Config.LogDirectory)) {
            Invoke-IfShouldProcess -Target $script:Config.LogDirectory -Action 'Create log directory' -ScriptBlock {
                New-Item -ItemType Directory -Path $script:Config.LogDirectory -Force | Out-Null
            }
        }

        if (Test-Path -LiteralPath $script:Config.LogDirectory) {
            $logFile = Join-Path $script:Config.LogDirectory ('powershell-sync-{0}.log' -f (Get-Date -Format 'yyyy-MM'))
            Invoke-IfShouldProcess -Target $logFile -Action 'Append log entry' -ScriptBlock {
                Add-Content -LiteralPath $logFile -Value $line
            }
        }
    }
}

function Test-ShouldProcess {
    param(
        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [string]$Action
    )

    return $PSCmdlet.ShouldProcess($Target, $Action)
}

function Invoke-IfShouldProcess {
    param(
        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    if (Test-ShouldProcess -Target $Target -Action $Action) {
        & $ScriptBlock
    }
}

function Resolve-TemplateValue {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [string]$RelativeRoot
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    $expanded = $Value
    try {
        $expanded = $ExecutionContext.InvokeCommand.ExpandString($expanded)
    }
    catch {
        # Leave value unchanged when expansion fails.
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($expanded)

    if ([string]::IsNullOrWhiteSpace($expanded)) {
        return $expanded
    }

    if ($RelativeRoot -and -not [System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath((Join-Path $RelativeRoot $expanded))
    }

    if ([System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath($expanded)
    }

    return $expanded
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Log -Message "Creating directory: $Path"
        Invoke-IfShouldProcess -Target $Path -Action 'Create directory' -ScriptBlock {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
}

function Ensure-EnvironmentVariable {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value,

        [ValidateSet('User','Machine')]
        [string]$Scope = 'User'
    )

    $current = [Environment]::GetEnvironmentVariable($Name, $Scope)
    if ($current -ne $Value) {
        Write-Log -Message "Setting environment variable $Name ($Scope) = $Value"

        Invoke-IfShouldProcess -Target "$Scope environment variable $Name" -Action "Set value to $Value" -ScriptBlock {
            [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
            Set-Item -Path "Env:$Name" -Value $Value
        }
    }
    else {
        Write-Log -Message "Environment variable $Name already set correctly"
    }
}

function Copy-IfDifferent {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Log -Level WARN -Message "Source path not found, skipping copy: $Source"
        return
    }

    $parent = Split-Path -Path $Destination -Parent
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    $shouldCopy = $true
    if (Test-Path -LiteralPath $Destination) {
        $sourceHash = Get-FileHash -LiteralPath $Source -Algorithm SHA256
        $destHash = Get-FileHash -LiteralPath $Destination -Algorithm SHA256
        $shouldCopy = $sourceHash.Hash -ne $destHash.Hash
    }

    if ($shouldCopy) {
        Write-Log -Message ('Copying {0} -> {1}' -f $Source, $Destination)
        Invoke-IfShouldProcess -Target $Destination -Action "Copy from $Source" -ScriptBlock {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force
        }
    }
}

function Get-UniqueStringList {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$InputObject
    )

    begin {
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $results = New-Object System.Collections.Generic.List[string]
    }

    process {
        if ([string]::IsNullOrWhiteSpace($InputObject)) {
            return
        }

        $value = $InputObject.Trim()
        if ($seen.Add($value)) {
            [void]$results.Add($value)
        }
    }

    end {
        $results
    }
}

function Read-Config {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $cfg = $raw | ConvertFrom-Json -Depth 50

    foreach ($required in 'RepoRoot','PersonalModulesPath','ExternalModulesPath','InventoryDirectory','ProfilesDirectory','SettingsDirectory','ThemesDirectory','FontsDirectory','LogDirectory','PersonalModules') {
        if (-not $cfg.PSObject.Properties.Name.Contains($required)) {
            throw "Missing required config property: $required"
        }
    }

    $repoRoot = Resolve-TemplateValue -Value $cfg.RepoRoot
    if (-not [System.IO.Path]::IsPathRooted($repoRoot)) {
        throw "RepoRoot must resolve to an absolute path. Current value: $($cfg.RepoRoot)"
    }

    $cfg.RepoRoot = $repoRoot
    $cfg.PersonalModulesPath = Resolve-TemplateValue -Value $cfg.PersonalModulesPath -RelativeRoot $cfg.RepoRoot
    $cfg.ExternalModulesPath = Resolve-TemplateValue -Value $cfg.ExternalModulesPath -RelativeRoot $cfg.RepoRoot
    $cfg.InventoryDirectory = Resolve-TemplateValue -Value $cfg.InventoryDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.ProfilesDirectory = Resolve-TemplateValue -Value $cfg.ProfilesDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.SettingsDirectory = Resolve-TemplateValue -Value $cfg.SettingsDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.ThemesDirectory = Resolve-TemplateValue -Value $cfg.ThemesDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.FontsDirectory = Resolve-TemplateValue -Value $cfg.FontsDirectory -RelativeRoot $cfg.RepoRoot
    $cfg.LogDirectory = Resolve-TemplateValue -Value $cfg.LogDirectory -RelativeRoot $cfg.RepoRoot

    if (-not $cfg.PSObject.Properties.Name.Contains('DefaultRepository') -or [string]::IsNullOrWhiteSpace($cfg.DefaultRepository)) {
        $cfg | Add-Member -NotePropertyName DefaultRepository -NotePropertyValue 'PSGallery'
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('Profiles')) {
        $cfg | Add-Member -NotePropertyName Profiles -NotePropertyValue @(
            [pscustomobject]@{ Source = '$PROFILE.CurrentUserCurrentHost'; Destination = 'Microsoft.PowerShell_profile.ps1' },
            [pscustomobject]@{ Source = '$PROFILE.CurrentUserAllHosts'; Destination = 'profile.ps1' }
        )
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('SettingsFiles')) {
        $cfg | Add-Member -NotePropertyName SettingsFiles -NotePropertyValue @()
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('OhMyPosh')) {
        $cfg | Add-Member -NotePropertyName OhMyPosh -NotePropertyValue ([pscustomobject]@{
            BackupEnabled     = $true
            BackupAllThemes   = $true
            ThemeSourcePath   = '$env:POSH_THEMES_PATH'
            ThemeBackupPath   = 'Themes\\oh-my-posh'
            RestoreTargetPath = 'Themes\\oh-my-posh'
        })
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('Fonts')) {
        $cfg | Add-Member -NotePropertyName Fonts -NotePropertyValue ([pscustomobject]@{
            BackupEnabled           = $true
            InstallOnApply          = $true
            Provider                = 'NerdFonts'
            DiscoveryEnabled        = $true
            Scope                   = 'CurrentUser'
            RequiredFonts           = @()
            InventoryPath           = 'Inventory\\fonts.json'
            AutoDetectFromInstalled = $true
            Files                   = @()
            RestoreDirectory        = '$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts'
        })
    }

    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('Provider')) {
        $cfg.Fonts | Add-Member -NotePropertyName Provider -NotePropertyValue 'NerdFonts'
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('DiscoveryEnabled')) {
        $cfg.Fonts | Add-Member -NotePropertyName DiscoveryEnabled -NotePropertyValue $true
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('Scope')) {
        $cfg.Fonts | Add-Member -NotePropertyName Scope -NotePropertyValue 'CurrentUser'
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('RequiredFonts')) {
        $cfg.Fonts | Add-Member -NotePropertyName RequiredFonts -NotePropertyValue @()
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('InventoryPath')) {
        $cfg.Fonts | Add-Member -NotePropertyName InventoryPath -NotePropertyValue 'Inventory\\fonts.json'
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('AutoDetectFromInstalled')) {
        $cfg.Fonts | Add-Member -NotePropertyName AutoDetectFromInstalled -NotePropertyValue $true
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('Files')) {
        $cfg.Fonts | Add-Member -NotePropertyName Files -NotePropertyValue @()
    }
    if (-not $cfg.Fonts.PSObject.Properties.Name.Contains('RestoreDirectory')) {
        $cfg.Fonts | Add-Member -NotePropertyName RestoreDirectory -NotePropertyValue '$env:LOCALAPPDATA\\Microsoft\\Windows\\Fonts'
    }

    if (-not $cfg.PSObject.Properties.Name.Contains('WindowsTerminal')) {
        $cfg | Add-Member -NotePropertyName WindowsTerminal -NotePropertyValue ([pscustomobject]@{
            BackupEnabled      = $true
            SettingsSourcePath = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
            SettingsBackupPath = 'Settings\\windows-terminal\\settings.json'
            RestoreTargetPath  = '$env:LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json'
        })
    }

    foreach ($item in @($cfg.Profiles)) {
        if ($null -eq $item) { continue }
        $item.Source = Resolve-TemplateValue -Value $item.Source
        $item.Destination = Resolve-TemplateValue -Value $item.Destination -RelativeRoot $cfg.ProfilesDirectory
    }

    foreach ($item in @($cfg.SettingsFiles)) {
        if ($null -eq $item) { continue }
        $item.Source = Resolve-TemplateValue -Value $item.Source
        $item.Destination = Resolve-TemplateValue -Value $item.Destination -RelativeRoot $cfg.SettingsDirectory
    }

    $cfg.OhMyPosh.ThemeSourcePath = Resolve-TemplateValue -Value $cfg.OhMyPosh.ThemeSourcePath
    $cfg.OhMyPosh.ThemeBackupPath = Resolve-TemplateValue -Value $cfg.OhMyPosh.ThemeBackupPath -RelativeRoot $cfg.RepoRoot
    $cfg.OhMyPosh.RestoreTargetPath = Resolve-TemplateValue -Value $cfg.OhMyPosh.RestoreTargetPath -RelativeRoot $cfg.RepoRoot

    $cfg.Fonts.InventoryPath = Resolve-TemplateValue -Value $cfg.Fonts.InventoryPath -RelativeRoot $cfg.RepoRoot
    $cfg.Fonts.RestoreDirectory = Resolve-TemplateValue -Value $cfg.Fonts.RestoreDirectory

    foreach ($item in @($cfg.Fonts.Files)) {
        if ($null -eq $item) { continue }
        if ($item.PSObject.Properties.Name.Contains('Source')) {
            $item.Source = Resolve-TemplateValue -Value $item.Source
        }
        if ($item.PSObject.Properties.Name.Contains('Destination')) {
            $item.Destination = Resolve-TemplateValue -Value $item.Destination -RelativeRoot $cfg.RepoRoot
        }
    }

    $cfg.WindowsTerminal.SettingsSourcePath = Resolve-TemplateValue -Value $cfg.WindowsTerminal.SettingsSourcePath
    $cfg.WindowsTerminal.SettingsBackupPath = Resolve-TemplateValue -Value $cfg.WindowsTerminal.SettingsBackupPath -RelativeRoot $cfg.RepoRoot
    $cfg.WindowsTerminal.RestoreTargetPath = Resolve-TemplateValue -Value $cfg.WindowsTerminal.RestoreTargetPath

    return $cfg
}

function ConvertTo-OrderedHashtable {
    param([Parameter(Mandatory)]$InputObject)

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $ordered[$key] = ConvertTo-OrderedHashtable -InputObject $InputObject[$key]
        }
        return $ordered
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $items = New-Object System.Collections.Generic.List[object]
        foreach ($item in $InputObject) {
            [void]$items.Add((ConvertTo-OrderedHashtable -InputObject $item))
        }
        return @($items)
    }

    if ($InputObject.PSObject -and $InputObject.PSObject.Properties.Count -gt 0) {
        $ordered = [ordered]@{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $ordered[$property.Name] = ConvertTo-OrderedHashtable -InputObject $property.Value
        }
        return $ordered
    }

    return $InputObject
}

function Update-ConfigFontsFromDiscovery {
    param(
        [Parameter(Mandatory)]
        [string[]]$RequiredFonts
    )

    $raw = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 50
    if (-not $raw.PSObject.Properties.Name.Contains('Fonts')) {
        $raw | Add-Member -NotePropertyName Fonts -NotePropertyValue ([pscustomobject]@{})
    }

    $raw.Fonts.Provider = 'NerdFonts'
    $raw.Fonts.DiscoveryEnabled = $true
    $raw.Fonts.InstallOnApply = $true
    $raw.Fonts.Scope = if ($script:Config.Fonts.Scope) { $script:Config.Fonts.Scope } else { 'CurrentUser' }
    $raw.Fonts.InventoryPath = if ($script:Config.Fonts.InventoryPath) { $script:Config.Fonts.InventoryPath } else { 'Inventory\\fonts.json' }
    $raw.Fonts.RequiredFonts = @($RequiredFonts | Get-UniqueStringList | Sort-Object)

    $ordered = ConvertTo-OrderedHashtable -InputObject $raw
    $json = $ordered | ConvertTo-Json -Depth 50

    Write-Log -Message "Updating config font list at $ConfigPath"
    Invoke-IfShouldProcess -Target $ConfigPath -Action 'Write updated font configuration' -ScriptBlock {
        Set-Content -LiteralPath $ConfigPath -Value $json -Encoding UTF8
    }
}

function Assert-GitRepo {
    if (-not (Test-Path -LiteralPath (Join-Path $script:Config.RepoRoot '.git'))) {
        throw "RepoRoot is not a git repository: $($script:Config.RepoRoot)"
    }
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter()][switch]$CaptureOutput,
        [Parameter()][switch]$IgnoreExitCode
    )

    Assert-GitRepo
    $display = 'git ' + ($Arguments -join ' ')

    if (-not (Test-ShouldProcess -Target $script:Config.RepoRoot -Action $display)) {
        if ($CaptureOutput) { return @() }
        return
    }

    Write-Log -Message "Running: $display"
    Push-Location $script:Config.RepoRoot
    try {
        if ($CaptureOutput) {
            $output = & git @Arguments 2>&1
            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0 -and -not $IgnoreExitCode) {
                throw ('git command failed with exit code {0}: {1}`n{2}' -f $exitCode, $display, ($output -join [Environment]::NewLine))
            }
            return @($output)
        }

        & git @Arguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0 -and -not $IgnoreExitCode) {
            throw ('git command failed with exit code {0}: {1}' -f $exitCode, $display)
        }
    }
    finally {
        Pop-Location
    }
}

function Sync-PSModulePath {
    $preferred = @(
        $script:Config.PersonalModulesPath,
        $script:Config.ExternalModulesPath
    )

    foreach ($path in $preferred) {
        Ensure-Directory -Path $path
    }

    $existing = $env:PSModulePath -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -and
            $_ -notin $preferred -and
            $_ -notmatch 'OneDrive.*Documents\\PowerShell\\Modules' -and
            $_ -notmatch 'Documents\\PowerShell\\Modules'
        } |
        Get-UniqueStringList

    $env:PSModulePath = (@($preferred) + @($existing)) -join ';'
    Write-Log -Message ('PSModulePath synchronized. Preferred paths: {0}' -f ($preferred -join ', '))
}

function Initialize-Directories {
    foreach ($path in @(
        $script:Config.RepoRoot,
        $script:Config.PersonalModulesPath,
        $script:Config.ExternalModulesPath,
        $script:Config.InventoryDirectory,
        $script:Config.ProfilesDirectory,
        $script:Config.SettingsDirectory,
        $script:Config.ThemesDirectory,
        $script:Config.FontsDirectory,
        $script:Config.LogDirectory
    )) {
        Ensure-Directory -Path $path
    }
}

function Backup-Profiles {
    foreach ($item in @($script:Config.Profiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Source)) {
            Write-Log -Level WARN -Message "Profile source not found, skipping: $($item.Source)"
            continue
        }
        Copy-IfDifferent -Source $item.Source -Destination $item.Destination
    }
}

function Restore-Profiles {
    foreach ($item in @($script:Config.Profiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Destination)) {
            Write-Log -Level WARN -Message "Profile backup not found, skipping restore: $($item.Destination)"
            continue
        }
        Copy-IfDifferent -Source $item.Destination -Destination $item.Source
    }
}

function Backup-SettingsFiles {
    foreach ($item in @($script:Config.SettingsFiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Source)) {
            Write-Log -Level WARN -Message "Settings source not found, skipping: $($item.Source)"
            continue
        }
        Copy-IfDifferent -Source $item.Source -Destination $item.Destination
    }
}

function Restore-SettingsFiles {
    foreach ($item in @($script:Config.SettingsFiles)) {
        if (-not $item.Source -or -not $item.Destination) { continue }
        if (-not (Test-Path -LiteralPath $item.Destination)) {
            Write-Log -Level WARN -Message "Settings backup not found, skipping restore: $($item.Destination)"
            continue
        }
        Copy-IfDifferent -Source $item.Destination -Destination $item.Source
    }
}

function Backup-OhMyPoshThemes {
    if (-not $script:Config.OhMyPosh.BackupEnabled) {
        Write-Log -Message 'Skipping oh-my-posh theme backup because it is disabled.'
        return
    }

    $source = $script:Config.OhMyPosh.ThemeSourcePath
    $destination = $script:Config.OhMyPosh.ThemeBackupPath
    Ensure-Directory -Path $destination

    if (Test-Path -LiteralPath $source -PathType Container) {
        $themeFiles = Get-ChildItem -LiteralPath $source -Filter '*.omp.json' -File -ErrorAction SilentlyContinue
        foreach ($file in $themeFiles) {
            $target = Join-Path $destination $file.Name
            Copy-IfDifferent -Source $file.FullName -Destination $target
        }
        return
    }

    if (Test-Path -LiteralPath $source -PathType Leaf) {
        $target = if (Test-Path -LiteralPath $destination -PathType Container) {
            Join-Path $destination (Split-Path -Path $source -Leaf)
        }
        else {
            $destination
        }
        Copy-IfDifferent -Source $source -Destination $target
        return
    }

    Write-Log -Level WARN -Message "oh-my-posh theme source not found, skipping: $source"
}

function Restore-OhMyPoshThemes {
    if (-not $script:Config.OhMyPosh.BackupEnabled) {
        Write-Log -Message 'Skipping oh-my-posh theme restore because it is disabled.'
        return
    }

    $backup = $script:Config.OhMyPosh.ThemeBackupPath
    $target = $script:Config.OhMyPosh.RestoreTargetPath

    if ($backup -eq $target) {
        Write-Log -Message 'Skipping oh-my-posh restore because backup and restore targets are identical.'
        return
    }

    if (-not (Test-Path -LiteralPath $backup)) {
        Write-Log -Level WARN -Message "oh-my-posh theme backup not found, skipping restore: $backup"
        return
    }

    Ensure-Directory -Path $target
    Get-ChildItem -LiteralPath $backup -Filter '*.omp.json' -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            Copy-IfDifferent -Source $_.FullName -Destination (Join-Path $target $_.Name)
        }
}

function Get-NerdFontCandidatesFromLegacyConfig {
    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($item in @($script:Config.Fonts.Files)) {
        if ($null -eq $item) { continue }

        $candidate = $null
        if ($item.PSObject.Properties.Name.Contains('FontName') -and -not [string]::IsNullOrWhiteSpace($item.FontName)) {
            $candidate = $item.FontName -replace '\s+Nerd Font.*$', ''
            $candidate = $candidate -replace '\s+', ''
        }
        elseif ($item.PSObject.Properties.Name.Contains('Source') -and -not [string]::IsNullOrWhiteSpace($item.Source)) {
            $leaf = [System.IO.Path]::GetFileNameWithoutExtension($item.Source)
            $candidate = $leaf -replace '-(Thin|ThinItalic|ExtraLight|ExtraLightItalic|Light|LightItalic|Regular|Italic|Medium|MediumItalic|SemiBold|SemiBoldItalic|Bold|BoldItalic|ExtraBold|ExtraBoldItalic|Black|BlackItalic|SemiLight|SemiLightItalic)$', ''
            $candidate = $candidate -replace 'NerdFontMono$', ''
            $candidate = $candidate -replace 'NerdFontPropo$', ''
            $candidate = $candidate -replace 'NerdFont$', ''
        }

        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            [void]$candidates.Add($candidate)
        }
    }

    return @($candidates | Get-UniqueStringList | Sort-Object)
}

function Ensure-ModuleAvailable {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter()][string]$Repository = $script:Config.DefaultRepository,
        [Parameter()][switch]$ImportOnly,
        [Parameter()][switch]$AllowFailure
    )

    $module = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $module -and -not $ImportOnly) {
        Write-Log -Message "Module '$Name' not found locally. Attempting install from repository '$Repository'."
        try {
            Invoke-IfShouldProcess -Target "PowerShell module $Name" -Action "Install from repository $Repository" -ScriptBlock {
                Install-Module -Name $Name -Repository $Repository -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            }
        }
        catch {
            if ($AllowFailure) {
                Write-Log -Level WARN -Message "Failed to install module '$Name': $($_.Exception.Message)"
                return $false
            }
            throw
        }

        $module = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    }

    if (-not $module) {
        if ($AllowFailure) {
            Write-Log -Level WARN -Message "Module '$Name' is not available."
            return $false
        }
        throw "Module '$Name' is not available."
    }

    try {
        Import-Module -Name $module.Path -Force -ErrorAction Stop | Out-Null
        Write-Log -Message "Module '$Name' is available and imported."
        return $true
    }
    catch {
        if ($AllowFailure) {
            Write-Log -Level WARN -Message "Failed to import module '$Name': $($_.Exception.Message)"
            return $false
        }
        throw
    }
}

function Ensure-FontProviderPrerequisites {
    if (-not $script:Config.Fonts.InstallOnApply) {
        return $true
    }

    $provider = if ($script:Config.Fonts.Provider) { [string]$script:Config.Fonts.Provider } else { 'NerdFonts' }
    switch ($provider) {
        'NerdFonts' {
            $fontsReady = Ensure-ModuleAvailable -Name 'Fonts' -AllowFailure:$SkipFontInstallFailures
            $nerdFontsReady = Ensure-ModuleAvailable -Name 'NerdFonts' -AllowFailure:$SkipFontInstallFailures
            return ($fontsReady -and $nerdFontsReady)
        }
        default {
            Write-Log -Level WARN -Message "Unknown font provider '$provider'. Font restore will be skipped."
            return $false
        }
    }
}

function Get-NerdFontStyleSuffixPattern {
    return 'Thin|ThinItalic|ExtraLight|ExtraLightItalic|Light|LightItalic|Regular|Italic|Medium|MediumItalic|SemiBold|SemiBoldItalic|Bold|BoldItalic|ExtraBold|ExtraBoldItalic|Black|BlackItalic|SemiLight|SemiLightItalic'
}

function Convert-InstalledFontNameToNerdFontCandidate {
    param([Parameter(Mandatory)][string]$Name)

    if ($Name -notmatch 'NerdFont') {
        return $null
    }

    $stylePattern = Get-NerdFontStyleSuffixPattern
    $base = $Name -replace ('-(' + $stylePattern + ')$'), ''
    $base = $base -replace 'NerdFontMono$', ''
    $base = $base -replace 'NerdFontPropo$', ''
    $base = $base -replace 'NerdFont$', ''

    if ([string]::IsNullOrWhiteSpace($base)) {
        return $null
    }

    return $base.Trim()
}

function Get-InstalledNerdFontFamilies {
    $installedNames = @()
    try {
        if (-not (Ensure-ModuleAvailable -Name 'Fonts' -ImportOnly -AllowFailure)) {
            Write-Log -Level WARN -Message 'Fonts module is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        if (-not (Get-Command -Name 'Get-Font' -ErrorAction SilentlyContinue)) {
            Write-Log -Level WARN -Message 'Get-Font command is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        $installedNames = @(Get-Font | Select-Object -ExpandProperty Name)
    }
    catch {
        Write-Log -Level WARN -Message "Failed to enumerate installed fonts: $($_.Exception.Message)"
        return @()
    }

    $availableNames = @()
    try {
        if (-not (Ensure-ModuleAvailable -Name 'NerdFonts' -ImportOnly -AllowFailure)) {
            Write-Log -Level WARN -Message 'NerdFonts module is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        if (-not (Get-Command -Name 'Get-NerdFont' -ErrorAction SilentlyContinue)) {
            Write-Log -Level WARN -Message 'Get-NerdFont command is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        $availableNames = @(Get-NerdFont | Select-Object -ExpandProperty Name)
    }
    catch {
        Write-Log -Level WARN -Message "Failed to enumerate available NerdFonts names: $($_.Exception.Message)"
        return @()
    }

    $candidates = foreach ($name in $installedNames) {
        $candidate = Convert-InstalledFontNameToNerdFontCandidate -Name $name
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $candidate
        }
    }

    return @(
        $candidates |
            Get-UniqueStringList |
            Where-Object { $_ -in $availableNames } |
            Sort-Object
    )
}

function Get-DesiredNerdFontFamilies {
    $fromConfig = @($script:Config.Fonts.RequiredFonts | ForEach-Object { [string]$_ } | Get-UniqueStringList | Sort-Object)
    if ($fromConfig.Count -gt 0) {
        return $fromConfig
    }

    $fromLegacy = @(Get-NerdFontCandidatesFromLegacyConfig)
    if ($fromLegacy.Count -gt 0) {
        Write-Log -Level WARN -Message 'Fonts.RequiredFonts is empty. Falling back to legacy Fonts.Files-derived font list.'
        return $fromLegacy
    }

    return @()
}

function Export-Fonts {
    if (-not $script:Config.Fonts.BackupEnabled) {
        Write-Log -Message 'Skipping font export because it is disabled.'
        return
    }

    $desiredFonts = @(Get-DesiredNerdFontFamilies)
    $discoveredFonts = @()

    if ($script:Config.Fonts.DiscoveryEnabled -and $script:Config.Fonts.AutoDetectFromInstalled) {
        $discoveredFonts = @(Get-InstalledNerdFontFamilies)
    }

    $payload = [pscustomobject]@{
        Provider        = if ($script:Config.Fonts.Provider) { $script:Config.Fonts.Provider } else { 'NerdFonts' }
        Scope           = if ($script:Config.Fonts.Scope) { $script:Config.Fonts.Scope } else { 'CurrentUser' }
        ExportedAt      = (Get-Date).ToString('s')
        DesiredFonts    = @($desiredFonts)
        DiscoveredFonts = @($discoveredFonts)
        MissingFromConfig = @($discoveredFonts | Where-Object { $_ -notin $desiredFonts } | Sort-Object)
        MissingFromSystem = @($desiredFonts | Where-Object { $_ -notin $discoveredFonts } | Sort-Object)
    }

    $inventoryPath = $script:Config.Fonts.InventoryPath
    $parent = Split-Path -Path $inventoryPath -Parent
    if ($parent) {
        Ensure-Directory -Path $parent
    }

    Invoke-IfShouldProcess -Target $inventoryPath -Action 'Write font inventory' -ScriptBlock {
        $payload | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $inventoryPath -Encoding UTF8
    }

    Write-Log -Message ('Exported Nerd Font inventory with {0} desired font(s) and {1} discovered font(s).' -f $desiredFonts.Count, $discoveredFonts.Count)

    if ($payload.MissingFromConfig.Count -gt 0) {
        Write-Log -Level WARN -Message ('Installed Nerd Fonts missing from config: {0}' -f ($payload.MissingFromConfig -join ', '))
    }

    if ($payload.MissingFromSystem.Count -gt 0) {
        Write-Log -Level WARN -Message ('Configured Nerd Fonts not currently installed: {0}' -f ($payload.MissingFromSystem -join ', '))
    }

    if ($UpdateFontConfigFromDiscovery -and $discoveredFonts.Count -gt 0) {
        Update-ConfigFontsFromDiscovery -RequiredFonts $discoveredFonts
    }
}

function Install-RequiredNerdFonts {
    if (-not $script:Config.Fonts.InstallOnApply) {
        Write-Log -Message 'Skipping font install because InstallOnApply is disabled.'
        return
    }

    $requiredFonts = @(Get-DesiredNerdFontFamilies)
    if ($requiredFonts.Count -eq 0) {
        Write-Log -Message 'No required Nerd Fonts are configured. Skipping font install.'
        return
    }

    if (-not (Ensure-FontProviderPrerequisites)) {
        Write-Log -Level WARN -Message 'Font provider prerequisites are not available. Skipping font install.'
        return
    }

    if (-not (Get-Command -Name 'Get-NerdFont' -ErrorAction SilentlyContinue)) {
        $message = 'Get-NerdFont command is not available after importing NerdFonts.'
        if ($SkipFontInstallFailures) {
            Write-Log -Level WARN -Message $message
            return
        }
        throw $message
    }

    if (-not (Get-Command -Name 'Install-NerdFont' -ErrorAction SilentlyContinue)) {
        $message = 'Install-NerdFont command is not available after importing NerdFonts.'
        if ($SkipFontInstallFailures) {
            Write-Log -Level WARN -Message $message
            return
        }
        throw $message
    }

    $available = @(Get-NerdFont | Select-Object -ExpandProperty Name)

    foreach ($fontName in $requiredFonts) {
        if ($fontName -notin $available) {
            $message = "Configured Nerd Font '$fontName' is not recognized by Get-NerdFont."
            if ($SkipFontInstallFailures) {
                Write-Log -Level WARN -Message $message
                continue
            }
            throw $message
        }

        $installParameters = @{ Name = $fontName }
        if ($script:Config.Fonts.Scope -and $script:Config.Fonts.Scope -ne 'CurrentUser') {
            $installParameters.Scope = $script:Config.Fonts.Scope
        }

        Write-Log -Message "Installing Nerd Font '$fontName'"
        try {
            Invoke-IfShouldProcess -Target "Nerd Font $fontName" -Action 'Install font' -ScriptBlock {
                Install-NerdFont @installParameters
            }
        }
        catch {
            if ($SkipFontInstallFailures) {
                Write-Log -Level WARN -Message "Failed to install Nerd Font '$fontName': $($_.Exception.Message)"
                continue
            }
            throw
        }
    }
}

function Backup-WindowsTerminal {
    if (-not $script:Config.WindowsTerminal.BackupEnabled) {
        Write-Log -Message 'Skipping Windows Terminal backup because it is disabled.'
        return
    }

    $source = $script:Config.WindowsTerminal.SettingsSourcePath
    $backup = $script:Config.WindowsTerminal.SettingsBackupPath

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Log -Level WARN -Message "Windows Terminal settings not found, skipping backup: $source"
        return
    }

    Copy-IfDifferent -Source $source -Destination $backup

    try {
        $json = Get-Content -LiteralPath $source -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 50
        $profiles = @()
        if ($json.profiles -and $json.profiles.list) {
            foreach ($profile in @($json.profiles.list)) {
                $profiles += [pscustomobject]@{
                    Name     = $profile.name
                    FontFace = $profile.font.face
                    FontSize = $profile.font.size
                }
            }
        }

        $summary = [pscustomobject]@{
            ExportedAt     = (Get-Date).ToString('s')
            DefaultProfile = $json.defaultProfile
            Profiles       = $profiles
        }

        $summaryPath = Join-Path $script:Config.InventoryDirectory 'windows-terminal-summary.json'
        Invoke-IfShouldProcess -Target $summaryPath -Action 'Write Windows Terminal summary' -ScriptBlock {
            $summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
        }
    }
    catch {
        Write-Log -Level WARN -Message "Failed to parse Windows Terminal settings summary: $($_.Exception.Message)"
    }
}

function Restore-WindowsTerminal {
    if (-not $script:Config.WindowsTerminal.BackupEnabled) {
        Write-Log -Message 'Skipping Windows Terminal restore because it is disabled.'
        return
    }

    $backup = $script:Config.WindowsTerminal.SettingsBackupPath
    $target = $script:Config.WindowsTerminal.RestoreTargetPath

    if (-not (Test-Path -LiteralPath $backup)) {
        Write-Log -Level WARN -Message "Windows Terminal backup not found, skipping restore: $backup"
        return
    }

    Copy-IfDifferent -Source $backup -Destination $target
}

function Get-InstalledGalleryModuleRecords {
    $records = @()

    $powerShellGet = Get-Module -ListAvailable -Name PowerShellGet | Sort-Object Version -Descending | Select-Object -First 1
    if ($powerShellGet) {
        Import-Module -Name $powerShellGet.Path -ErrorAction SilentlyContinue | Out-Null
    }

    if (Get-Command -Name Get-InstalledModule -ErrorAction SilentlyContinue) {
        try {
            $records = @(Get-InstalledModule -ErrorAction Stop | Sort-Object Name, Version)
        }
        catch {
            Write-Log -Level WARN -Message "Get-InstalledModule failed, continuing with empty gallery manifest: $($_.Exception.Message)"
            $records = @()
        }
    }

    return $records
}

function Export-ExternalModuleManifest {
    $installed = Get-InstalledGalleryModuleRecords
    $manifest = foreach ($module in $installed) {
        [pscustomobject]@{
            Name       = $module.Name
            Version    = $module.Version.ToString()
            Repository = if ($module.Repository) { $module.Repository } else { $script:Config.DefaultRepository }
        }
    }

    $manifestPath = Join-Path $script:Config.InventoryDirectory 'gallery-modules.json'
    Invoke-IfShouldProcess -Target $manifestPath -Action 'Write external module manifest' -ScriptBlock {
        $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }

    Write-Log -Message ('Exported gallery module manifest with {0} entries.' -f @($manifest).Count)
}

function Install-ExternalModulesFromManifest {
    $manifestPath = Join-Path $script:Config.InventoryDirectory 'gallery-modules.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-Log -Level WARN -Message "Gallery module manifest not found, skipping install: $manifestPath"
        return
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    if ($null -eq $manifest) {
        Write-Log -Message 'Gallery module manifest is empty, nothing to install.'
        return
    }

    foreach ($entry in @($manifest)) {
        $targetVersionPath = Join-Path (Join-Path $script:Config.ExternalModulesPath $entry.Name) $entry.Version
        if (Test-Path -LiteralPath $targetVersionPath) {
            Write-Log -Message ("External module already present: {0} {1}" -f $entry.Name, $entry.Version)
            continue
        }

        $params = @{
            Name            = $entry.Name
            Path            = $script:Config.ExternalModulesPath
            RequiredVersion = $entry.Version
            Force           = $true
        }
        if ($entry.Repository) {
            $params.Repository = $entry.Repository
        }

        Write-Log -Message ("Saving module {0} {1} to {2}" -f $entry.Name, $entry.Version, $script:Config.ExternalModulesPath)
        if (-not $script:WhatIfPreference) {
            Save-Module @params
        }
    }

    if ($PruneExternalModules) {
        Write-Log -Level WARN -Message 'PruneExternalModules was specified. Remove untracked versions manually if needed; automatic prune is not implemented.'
    }
}

function Export-MachineState {
    $machineState = [pscustomobject]@{
        ComputerName        = $env:COMPUTERNAME
        UserName            = $env:USERNAME
        ExportedAt          = (Get-Date).ToString('s')
        PowerShellVersion   = $PSVersionTable.PSVersion.ToString()
        PSModulePath        = $env:PSModulePath -split ';'
        PersonalModulesPath = $script:Config.PersonalModulesPath
        ExternalModulesPath = $script:Config.ExternalModulesPath
        ActiveThemeHint     = $null
    }

    $hostProfile = $script:Config.Profiles | Select-Object -First 1
    if ($hostProfile -and (Test-Path -LiteralPath $hostProfile.Destination)) {
        try {
            $content = Get-Content -LiteralPath $hostProfile.Destination -Raw -Encoding UTF8
            if ($content -match '--config\s+["''](?<path>[^"'']+)["'']') {
                $themePath = $matches['path']
                $machineState.ActiveThemeHint = $themePath
            }
        }
        catch {
            Write-Log -Level WARN -Message "Failed to infer active oh-my-posh theme from profile backup: $($_.Exception.Message)"
        }
    }

    $statePath = Join-Path $script:Config.InventoryDirectory 'machine-state.json'
    Invoke-IfShouldProcess -Target $statePath -Action 'Write machine state inventory' -ScriptBlock {
        $machineState | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
}

function Get-GitPendingChanges {
    $status = Invoke-Git -Arguments @('status','--porcelain') -CaptureOutput
    return @($status | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Invoke-GitSync {
    if (-not $script:GitEnabled) {
        if ($SkipGit) {
            Write-Log -Message 'Skipping git operations because -SkipGit was specified.'
        }
        else {
            Write-Log -Message 'Skipping git operations because Git sync is disabled by default. Use -EnableGitSync to turn it on.'
        }
        return
    }

    $pending = Get-GitPendingChanges
    if (@($pending).Count -eq 0) {
        Write-Log -Message 'No git changes detected after sync export.'
        return
    }

    Invoke-Git -Arguments @('add','-A')

    $message = 'PowerShell sync from {0} on {1}' -f $env:COMPUTERNAME, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Invoke-Git -Arguments @('commit','-m',$message)

    if (-not $SkipPush) {
        Invoke-Git -Arguments @('push')
    }
}

function Register-SyncScheduledTask {
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        throw 'Unable to determine script path for scheduled task registration.'
    }

    $hours, $minutes = $ScheduledTime.Split(':')
    $startBoundary = Get-Date -Day ([Math]::Min([DateTime]::DaysInMonth((Get-Date).Year, (Get-Date).Month), $ScheduledDayOfMonth)) -Hour ([int]$hours) -Minute ([int]$minutes) -Second 0
    if ($startBoundary -lt (Get-Date)) {
        $next = (Get-Date).AddMonths(1)
        $startBoundary = Get-Date -Year $next.Year -Month $next.Month -Day ([Math]::Min([DateTime]::DaysInMonth($next.Year, $next.Month), $ScheduledDayOfMonth)) -Hour ([int]$hours) -Minute ([int]$minutes) -Second 0
    }

    $taskName = 'PowerShell Environment Sync'
    $argument = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -Mode Sync' -f $scriptPath)

    Write-Log -Message ("Registering scheduled task '{0}' for monthly sync at day {1} {2}" -f $taskName, $ScheduledDayOfMonth, $ScheduledTime)
    Invoke-IfShouldProcess -Target $taskName -Action 'Register scheduled task' -ScriptBlock {
        $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $argument
        $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth $ScheduledDayOfMonth -At $startBoundary.TimeOfDay
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    }
}

function Invoke-Apply {
    Sync-PSModulePath
    Initialize-Directories

    # Phase 1: bootstrap runtime dependencies required by later providers.
    Install-ExternalModulesFromManifest
    Ensure-FontProviderPrerequisites | Out-Null

    # Phase 2: apply repo-managed state.
    Restore-Profiles
    Restore-SettingsFiles
    Restore-OhMyPoshThemes
    Install-RequiredNerdFonts
    Restore-WindowsTerminal
}

function Invoke-Export {
    Sync-PSModulePath
    Initialize-Directories
    Backup-Profiles
    Backup-SettingsFiles
    Backup-OhMyPoshThemes
    Export-Fonts
    Backup-WindowsTerminal
    Export-ExternalModuleManifest
    Export-MachineState
}

$script:Config = Read-Config -Path $ConfigPath
Write-Log -Message ('Loaded configuration from {0}' -f $ConfigPath)

Initialize-Directories
Ensure-EnvironmentVariable -Name 'PS_CONFIG_ROOT' -Value $script:Config.RepoRoot -Scope 'User'

if ($script:GitEnabled) {
    Write-Log -Message 'Git sync is enabled for this run.'
}
else {
    Write-Log -Message 'Git sync is disabled for this run.'
}

switch ($Mode) {
    'Apply' {
        if ($script:GitEnabled -and -not $SkipPull) {
            Invoke-Git -Arguments @('pull','--rebase','--autostash')
        }
        Invoke-Apply
    }
    'Export' {
        Invoke-Export
        if ($script:GitEnabled) {
            Invoke-GitSync
        }
    }
    'Sync' {
        if ($script:GitEnabled -and -not $SkipPull) {
            Invoke-Git -Arguments @('pull','--rebase','--autostash')
        }
        Invoke-Apply
        Invoke-Export
        if ($script:GitEnabled) {
            Invoke-GitSync
        }
    }
    'RegisterScheduledTask' {
        Register-SyncScheduledTask
    }
    default {
        throw "Unsupported mode: $Mode"
    }
}
