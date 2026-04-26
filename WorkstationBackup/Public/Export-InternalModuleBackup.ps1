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