function Write-BackupLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO',

        [Parameter()]
        [string]$LogDirectory
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message
    Write-Host $line

    if ($LogDirectory) {
        if (-not (Test-Path -LiteralPath $LogDirectory)) {
            if ($PSCmdlet.ShouldProcess($LogDirectory, 'Create log directory')) {
                New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
            }
        }

        if (Test-Path -LiteralPath $LogDirectory) {
            $logFile = Join-Path $LogDirectory ('workstation-backup-{0}.log' -f (Get-Date -Format 'yyyy-MM'))
            if ($PSCmdlet.ShouldProcess($logFile, 'Append log entry')) {
                Add-Content -LiteralPath $logFile -Value $line
            }
        }
    }
}
