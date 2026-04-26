function Get-DesiredNerdFontFamilies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $required = @()

    if ($Config.Fonts.PSObject.Properties.Name.Contains('RequiredFonts') -and $null -ne $Config.Fonts.RequiredFonts) {
        $required = @($Config.Fonts.RequiredFonts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    if (@($required).Count -gt 0) {
        return @($required | Sort-Object -Unique)
    }

    $fromLegacy = @(Get-NerdFontCandidatesFromLegacyConfig -Config $Config)
    if (@($fromLegacy).Count -gt 0) {
        Write-BackupLog -Level 'WARN' -Message 'Fonts.RequiredFonts is empty. Falling back to legacy Fonts.Files-derived font list.'
        return @($fromLegacy | Sort-Object -Unique)
    }

    return @()
}