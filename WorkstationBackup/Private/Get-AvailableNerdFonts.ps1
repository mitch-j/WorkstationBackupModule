function Get-AvailableNerdFont {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Install-ModuleAvailable -Name 'NerdFonts' -Repository $Config.DefaultRepository -ImportOnly -AllowFailure)) {
        Write-BackupLog -Level 'WARN' -Message 'NerdFonts module is not available. Available font discovery will be skipped.'
        return @()
    }

    if (-not (Get-Command -Name 'Get-NerdFont' -ErrorAction SilentlyContinue)) {
        Write-BackupLog -Level 'WARN' -Message 'Get-NerdFont command is not available. Available font discovery will be skipped.'
        return @()
    }

    try {
        return @(Get-NerdFont | Select-Object -ExpandProperty Name | Sort-Object -Unique)
    }
    catch {
        Write-BackupLog -Level 'WARN' -Message "Failed to enumerate Nerd Fonts from provider: $($_.Exception.Message)"
        return @()
    }
}