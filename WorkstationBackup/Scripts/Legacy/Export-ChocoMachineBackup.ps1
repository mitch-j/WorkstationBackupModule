<#
.SYNOPSIS
Exports a dated Chocolatey package manifest for the current workstation.

.DESCRIPTION
Export-ChocoMachineBackup.ps1 creates a machine-specific Chocolatey export file using
Chocolatey's native .config manifest format.

The output is intended to support workstation rebuilds, package inventory tracking,
and recurring configuration backups. Each run writes a dated manifest beneath a
host-specific directory under the repository's Config folder.

The script can optionally:
- include installed package versions in the export
- retain only the most recent N exports for the machine
- overwrite the current day's export file

The generated .config file can later be used with Chocolatey to reinstall packages.

.PARAMETER RepoRoot
Path to the repository root.

Default:
Parent of the directory containing this script.

.PARAMETER ConfigRoot
Path to the Config directory under the repository.

Default:
<RepoRoot>\Config

.PARAMETER HostName
Machine name to use for the output subfolder and file name.

Default:
$env:COMPUTERNAME

.PARAMETER RetentionCount
Number of most recent machine manifests to keep for the selected host.

Default:
5

.PARAMETER IncludeVersions
When specified, exports version-pinned package entries using Chocolatey's
include-version-numbers option.

.PARAMETER AllowOverwriteToday
Allows overwriting today's export file if it already exists.

By default, the script throws if today's file already exists to avoid replacing
a same-day snapshot unintentionally.

.PARAMETER WhatIf
Shows what would happen without making changes where supported.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Export-ChocoMachineBackup.ps1

Creates a dated Chocolatey package manifest for the current machine beneath the
repository Config folder and applies default retention.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Export-ChocoMachineBackup.ps1 -IncludeVersions

Creates a Chocolatey package manifest that includes explicit package versions.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Export-ChocoMachineBackup.ps1 -RetentionCount 10

Creates a new export and keeps the 10 most recent manifest files for the machine.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Export-ChocoMachineBackup.ps1 -AllowOverwriteToday

Creates or replaces today's manifest file for the machine.

.EXAMPLE
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Export-ChocoMachineBackup.ps1 -RepoRoot C:\Dev\work\ps-config-work

Runs the export using the specified repository root.

.NOTES
This script requires:
- PowerShell 7 or later
- Chocolatey available in PATH

Output files are written in Chocolatey's .config format and are suitable for later reuse
during package restoration workflows.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RepoRoot,

    [Parameter()]
    [string]$ConfigRoot,

    [Parameter()]
    [string]$HostName = $env:COMPUTERNAME,

    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$RetentionCount = 5,

    [Parameter()]
    [switch]$IncludeVersions,

    [Parameter()]
    [switch]$AllowOverwriteToday
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-ChocoBackupLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] [$Level] $Message"
}

function Assert-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$CommandName' was not found in PATH."
    }
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, 'Create directory')) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-ChocoBackupLog "Created directory $Path"
        }
    }
}

function Get-MachineManifestFiles {
    param(
        [Parameter(Mandatory)]
        [string]$Directory,

        [Parameter(Mandatory)]
        [string]$HostName
    )

    if (-not (Test-Path -LiteralPath $Directory)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $Directory -File -Filter ("choco-manifest-{0}-*.config" -f $HostName) |
            Sort-Object LastWriteTimeUtc -Descending
    )
}

function Remove-OldMachineManifests {
    param(
        [Parameter(Mandatory)]
        [string]$Directory,

        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [int]$RetentionCount
    )

    $existingFiles = @(Get-MachineManifestFiles -Directory $Directory -HostName $HostName)

    if ($existingFiles.Count -le $RetentionCount) {
        Write-ChocoBackupLog "Retention check passed. Found $($existingFiles.Count) file(s), keeping up to $RetentionCount."
        return
    }

    $filesToRemove = @($existingFiles | Select-Object -Skip $RetentionCount)
    foreach ($file in $filesToRemove) {
        if ($PSCmdlet.ShouldProcess($file.FullName, 'Remove old Chocolatey machine manifest')) {
            Remove-Item -LiteralPath $file.FullName -Force
            Write-ChocoBackupLog "Removed old machine manifest $($file.FullName)"
        }
    }
}

try {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "This script requires PowerShell 7 or higher. Run it with 'pwsh'."
    }

    Assert-CommandExists -CommandName 'choco'

    $scriptDirectory = Split-Path -Path $PSCommandPath -Parent

    if (-not $RepoRoot) {
        $RepoRoot = Split-Path -Path $scriptDirectory -Parent
    }

    $RepoRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RepoRoot)

    if (-not $ConfigRoot) {
        $ConfigRoot = Join-Path $RepoRoot 'Config'
    }
    else {
        $ConfigRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigRoot)
    }

    if ([string]::IsNullOrWhiteSpace($HostName)) {
        throw 'HostName cannot be empty.'
    }

    $safeHostName = $HostName.Trim()
    $hostConfigDirectory = Join-Path $ConfigRoot $safeHostName
    $dateStamp = Get-Date -Format 'yyyy-MM-dd'
    $outputFileName = "choco-manifest-{0}-{1}.config" -f $safeHostName, $dateStamp
    $outputFilePath = Join-Path $hostConfigDirectory $outputFileName

    Write-ChocoBackupLog "Using repository root $RepoRoot"
    Write-ChocoBackupLog "Using config root $ConfigRoot"
    Write-ChocoBackupLog "Using host name $safeHostName"
    Write-ChocoBackupLog "Machine manifest path will be $outputFilePath"

    Ensure-Directory -Path $ConfigRoot
    Ensure-Directory -Path $hostConfigDirectory

    if ((Test-Path -LiteralPath $outputFilePath) -and (-not $AllowOverwriteToday)) {
        throw "Today's machine manifest already exists at '$outputFilePath'. Use -AllowOverwriteToday to replace it."
    }

    $chocoArguments = @(
        'export',
        "--output-file-path=$outputFilePath"
    )

    if ($IncludeVersions) {
        $chocoArguments += '--include-version-numbers'
    }

    Write-ChocoBackupLog ("Running Chocolatey export: choco " + ($chocoArguments -join ' '))

    if ($WhatIfPreference) {
        return
    }

    & choco @chocoArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Chocolatey export failed with exit code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $outputFilePath)) {
        throw "Chocolatey export completed but output file was not created: '$outputFilePath'."
    }

    Write-ChocoBackupLog "Created machine manifest $outputFilePath"

    Remove-OldMachineManifests -Directory $hostConfigDirectory -HostName $safeHostName -RetentionCount $RetentionCount
}
catch {
    Write-ChocoBackupLog $_.Exception.Message 'ERROR'
    throw
}
