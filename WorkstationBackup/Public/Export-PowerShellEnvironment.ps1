function Export-PowerShellEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$LegacyScriptPath,

        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [switch]$SkipGit,

        [Parameter()]
        [switch]$UpdateFontConfigFromDiscovery,

        [Parameter()]
        [switch]$SkipFontInstallFailures
    )

    $RepoRoot = Get-WorkstationBackupRoot -RepoRoot $RepoRoot -ModuleRoot $PSScriptRoot
    if (-not $LegacyScriptPath) {
        $LegacyScriptPath = Join-Path $RepoRoot 'Sync-PowerShellEnvironment.ps1'
    }

    if (-not (Test-Path -LiteralPath $LegacyScriptPath)) {
        throw "Legacy PowerShell environment script was not found at '$LegacyScriptPath'. During the migration, this function expects the original script to stay in place."
    }

    $arguments = @('-Mode', 'Export')
    if ($ConfigPath) { $arguments += @('-ConfigPath', $ConfigPath) }
    if ($SkipGit) { $arguments += '-SkipGit' }
    if ($UpdateFontConfigFromDiscovery) { $arguments += '-UpdateFontConfigFromDiscovery' }
    if ($SkipFontInstallFailures) { $arguments += '-SkipFontInstallFailures' }
    if ($WhatIfPreference) { $arguments += '-WhatIf' }

    Write-BackupLog "Delegating PowerShell environment export to legacy script: $LegacyScriptPath"

    if ($PSCmdlet.ShouldProcess($LegacyScriptPath, 'Run legacy Export mode')) {
        & $LegacyScriptPath @arguments
        if ($LASTEXITCODE -ne 0) {
            throw 'Legacy PowerShell environment export failed.'
        }
    }
}
