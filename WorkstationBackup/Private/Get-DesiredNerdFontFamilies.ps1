function Get-DesiredNerdFontFamily {
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

    return @($required | Sort-Object -Unique)
}