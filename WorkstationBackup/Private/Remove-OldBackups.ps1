function Remove-OldBackup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string]$Directory,

        [Parameter(Mandatory)]
        [string]$Filter,

        [Parameter(Mandatory)]
        [ValidateRange(1, 3650)]
        [int]$RetentionCount,

        [Parameter()]
        [string]$Description = 'old backup file'
    )

    if (-not (Test-Path -LiteralPath $Directory)) {
        return
    }

    $existingFiles = @(
        Get-ChildItem -LiteralPath $Directory -File -Filter $Filter |
            Sort-Object LastWriteTimeUtc -Descending
    )

    if ($existingFiles.Count -le $RetentionCount) {
        return
    }

    $filesToRemove = @($existingFiles | Select-Object -Skip $RetentionCount)
    foreach ($file in $filesToRemove) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove $Description")) {
            Remove-Item -LiteralPath $file.FullName -Force
            Write-BackupLog "Removed $Description $($file.FullName)"
        }
    }
}
