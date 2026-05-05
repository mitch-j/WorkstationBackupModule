<#
.SYNOPSIS
    Exports Chocolatey package metadata to the backup repository.

.DESCRIPTION
    Uses Chocolatey's export feature to write a machine-specific manifest into the
    backup repository config directory. This manifest can be persisted in Git and
    restored or reenforced on another workstation.

.PARAMETER RepoRoot
    Root directory of the backup repository. Defaults to the repo root resolved from
    the module location.

.PARAMETER ConfigRoot
    Optional alternate root for the backup configuration files. Defaults to
    $RepoRoot\Config.

.PARAMETER HostName
    Host name used to name the machine-specific backup directory and manifest file.

.PARAMETER RetentionCount
    Number of previous Chocolatey manifests to retain. Older manifests are deleted.

.PARAMETER IncludeVersions
    Include package version numbers in the exported Chocolatey manifest.

.PARAMETER AllowOverwriteToday
    Allow overwriting today's manifest file if it already exists.

.EXAMPLE
    Export-ChocoMachineBackup

    Exports Chocolatey state to the default backup repo config directory.

.EXAMPLE
    Export-ChocoMachineBackup -RepoRoot 'C:\Dev\work\backup-repo' -IncludeVersions

    Exports with package versions included to a specific backup repository.

.NOTES
    - Requires Chocolatey installed and available in PATH.
    - This command is safe with ShouldProcess and WhatIf support.

.INPUTS
    None.

.OUTPUTS
    PSCustomObject
#>
function Export-ChocoMachineBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$ConfigRoot,

        [Parameter()]
        [string]$HostName = (Get-WorkstationIdentity).ComputerName,

        [Parameter()]
        [ValidateRange(1, 365)]
        [int]$RetentionCount = 5,

        [Parameter()]
        [switch]$IncludeVersions,

        [Parameter()]
        [switch]$AllowOverwriteToday
    )

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "This function requires PowerShell 7 or higher. Run it with 'pwsh'."
    }

    Test-RequiredCommand -CommandName 'choco' | Out-Null

    $RepoRoot = Get-WorkstationBackupRoot -RepoRoot $RepoRoot -ModuleRoot $PSScriptRoot
    if (-not $ConfigRoot) {
        $ConfigRoot = Join-Path $RepoRoot 'Config'
    }
    else {
        $ConfigRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigRoot)
    }

    $hostConfigDirectory = Join-Path $ConfigRoot $HostName.Trim()
    $outputFileName = Get-BackupFileName -Prefix 'choco-manifest' -HostName $HostName -Extension '.config'
    $outputFilePath = Join-Path $hostConfigDirectory $outputFileName

    foreach ($path in @($ConfigRoot, $hostConfigDirectory)) {
        if (-not (Test-Path -LiteralPath $path)) {
            if ($PSCmdlet.ShouldProcess($path, 'Create directory')) {
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                Write-BackupLog "Created directory $path"
            }
        }
    }

    if ((Test-Path -LiteralPath $outputFilePath) -and (-not $AllowOverwriteToday)) {
        throw "Today's machine manifest already exists at '$outputFilePath'. Use -AllowOverwriteToday to replace it."
    }

    $chocoArguments = @('export', "--output-file-path=$outputFilePath")
    if ($IncludeVersions) {
        $chocoArguments += '--include-version-numbers'
    }

    Write-BackupLog ("Running Chocolatey export: choco " + ($chocoArguments -join ' '))

    if ($PSCmdlet.ShouldProcess("Chocolatey packages", "Export to '$outputFilePath'")) {
        & choco @chocoArguments
        if ($LASTEXITCODE -ne 0) {
            throw 'Chocolatey export failed.'
        }

        Remove-OldBackup -Directory $hostConfigDirectory -Filter ("choco-manifest-{0}-*.config" -f $HostName.Trim()) -RetentionCount $RetentionCount -Description 'old Chocolatey machine manifest'
    }

    Write-BackupLog "Chocolatey export completed successfully: $outputFilePath"

    [pscustomobject]@{
        RepoRoot       = $RepoRoot
        ConfigRoot     = $ConfigRoot
        HostName       = $HostName
        OutputFilePath = $outputFilePath
        RetentionCount = $RetentionCount
    }
}
