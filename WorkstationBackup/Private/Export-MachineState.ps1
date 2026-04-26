function Export-MachineState {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $machineState = [pscustomobject]@{
        ComputerName        = $env:COMPUTERNAME
        UserName            = $env:USERNAME
        ExportedAt          = (Get-Date).ToString('s')
        PowerShellVersion   = $PSVersionTable.PSVersion.ToString()
        PSModulePath        = $env:PSModulePath -split ';'
        PersonalModulesPath = $Config.PersonalModulesPath
        ExternalModulesPath = $Config.ExternalModulesPath
        ActiveThemeHint     = $null
    }

    $hostProfile = @($Config.Profiles | Select-Object -First 1)[0]
    if ($hostProfile -and $hostProfile.Destination -and (Test-Path -LiteralPath $hostProfile.Destination)) {
        try {
            $content = Get-Content -LiteralPath $hostProfile.Destination -Raw -Encoding UTF8
            if ($content -match '--config\s+["''](?<path>[^"'']+)["'']') {
                $machineState.ActiveThemeHint = $matches['path']
            }
        }
        catch {
            Write-BackupLog -Level 'WARN' -Message "Failed to infer active oh-my-posh theme from profile backup: $($_.Exception.Message)"
        }
    }

    $statePath = Join-Path $Config.InventoryDirectory 'machine-state.json'
    if ($PSCmdlet.ShouldProcess($statePath, 'Write machine state inventory')) {
        $machineState | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
}