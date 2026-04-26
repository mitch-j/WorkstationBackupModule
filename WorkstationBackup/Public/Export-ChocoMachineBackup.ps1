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
    $outputFileName = New-BackupFileName -Prefix 'choco-manifest' -HostName $HostName -Extension '.config'
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

    if ($WhatIfPreference) {
        return [pscustomobject]@{
            RepoRoot       = $RepoRoot
            ConfigRoot     = $ConfigRoot
            HostName       = $HostName
            OutputFilePath = $outputFilePath
            RetentionCount = $RetentionCount
        }
    }

    & choco @chocoArguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Chocolatey export failed.'
    }

    Remove-OldBackups -Directory $hostConfigDirectory -Filter ("choco-manifest-{0}-*.config" -f $HostName.Trim()) -RetentionCount $RetentionCount -Description 'old Chocolatey machine manifest'

    Write-BackupLog "Chocolatey export completed successfully: $outputFilePath"

    [pscustomobject]@{
        RepoRoot       = $RepoRoot
        ConfigRoot     = $ConfigRoot
        HostName       = $HostName
        OutputFilePath = $outputFilePath
        RetentionCount = $RetentionCount
    }
}
