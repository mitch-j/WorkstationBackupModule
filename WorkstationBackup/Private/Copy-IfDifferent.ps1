function Copy-IfDifferent {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-BackupLog -Level WARN -Message "Source path not found, skipping copy: $Source"
        return
    }

    $parent = Split-Path -Path $Destination -Parent
    if ($parent) {
        New-Directory -Path $parent
    }

    $shouldCopy = $true
    if (Test-Path -LiteralPath $Destination) {
        $sourceHash = Get-FileHash -LiteralPath $Source -Algorithm SHA256
        $destHash = Get-FileHash -LiteralPath $Destination -Algorithm SHA256
        $shouldCopy = $sourceHash.Hash -ne $destHash.Hash
    }

    if ($shouldCopy) {
        Write-BackupLog -Message ('Copying {0} -> {1}' -f $Source, $Destination)
        if ($PSCmdlet.ShouldProcess($Destination, "Copy from $Source")) {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force
        }
    }
}