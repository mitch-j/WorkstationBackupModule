<#
.SYNOPSIS
    Packages internal PowerShell modules into archive files for backup.

.DESCRIPTION
    Compresses each folder in the internal module source root into a ZIP archive
    and writes the results into the specified destination root. Optionally writes
    a manifest describing the archived modules.

.PARAMETER SourceRoot
    Directory containing the internal modules to back up.

.PARAMETER DestinationRoot
    Directory where module archives will be written.

.PARAMETER IncludeModules
    Specific module names to include in the backup. If empty, all modules are included.

.PARAMETER ExcludeModules
    Specific module names to exclude from the backup.

.PARAMETER WriteManifest
    Write a JSON manifest file listing archived internal modules.

.EXAMPLE
    Export-InternalModuleBackup -SourceRoot 'C:\Modules\Internal' -DestinationRoot 'C:\Backup\Modules'

    Archives all internal modules into the backup repository.

.EXAMPLE
    Export-InternalModuleBackup -SourceRoot 'C:\Modules\Internal' -DestinationRoot 'C:\Backup\Modules' -ExcludeModules @('TempModule') -WriteManifest

    Archives internal modules while excluding a specific module and writes a manifest.

.NOTES
    - This command uses Compress-Archive and requires Windows PowerShell compression support.
    - If an archive already exists, it is replaced when the command runs.

.INPUTS
    None.

.OUTPUTS
    System.Object[]
#>
function Export-InternalModuleBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceRoot,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationRoot,

        [Parameter()]
        [string[]]$IncludeModules = @(),

        [Parameter()]
        [string[]]$ExcludeModules = @(),

        [Parameter()]
        [switch]$WriteManifest
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        throw "Internal module source root not found: $SourceRoot"
    }

    if (-not (Test-Path -LiteralPath $DestinationRoot)) {
        if ($PSCmdlet.ShouldProcess($DestinationRoot, 'Create backup module destination directory')) {
            New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
        }
    }

    $moduleDirectories = Get-ChildItem -LiteralPath $SourceRoot -Directory | Sort-Object Name

    if ($IncludeModules.Count -gt 0) {
        $moduleDirectories = $moduleDirectories | Where-Object { $_.Name -in $IncludeModules }
    }

    if ($ExcludeModules.Count -gt 0) {
        $moduleDirectories = $moduleDirectories | Where-Object { $_.Name -notin $ExcludeModules }
    }

    $manifestEntries = @()

    foreach ($moduleDirectory in $moduleDirectories) {
        $moduleName = $moduleDirectory.Name
        $moduleSourcePath = $moduleDirectory.FullName
        $archivePath = Join-Path $DestinationRoot ("{0}.zip" -f $moduleName)

        Write-BackupLog -Message "Packaging internal module '$moduleName' from '$moduleSourcePath'"

        if ($PSCmdlet.ShouldProcess($moduleName, "Create module archive '$archivePath'")) {
            if (Test-Path -LiteralPath $archivePath) {
                Remove-Item -LiteralPath $archivePath -Force
            }

            Compress-Archive -Path (Join-Path $moduleSourcePath '*') -DestinationPath $archivePath -Force
        }

        $manifestEntries += [pscustomobject]@{
            Name          = $moduleName
            SourcePath    = $moduleSourcePath
            ArchivePath   = $archivePath
            ArchivedOnUtc = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    if ($WriteManifest) {
        $manifestPath = Join-Path $DestinationRoot 'InternalModulesManifest.json'

        if ($PSCmdlet.ShouldProcess($manifestPath, 'Write internal modules manifest')) {
            $manifestEntries |
            ConvertTo-Json -Depth 4 |
            Set-Content -LiteralPath $manifestPath -Encoding utf8
        }

        Write-BackupLog -Message "Wrote internal module manifest to '$manifestPath'"
    }

    return $manifestEntries
}