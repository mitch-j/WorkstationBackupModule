function Convert-InstalledFontNameToNerdFontCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if ($Name -notmatch 'NerdFont') {
        return $null
    }

    $stylePattern = Get-NerdFontStyleSuffixPattern
    $base = $Name -replace ('-(' + $stylePattern + ')$'), ''
    $base = $base -replace 'NerdFontMono$', ''
    $base = $base -replace 'NerdFontPropo$', ''
    $base = $base -replace 'NerdFont$', ''

    if ([string]::IsNullOrWhiteSpace($base)) {
        return $null
    }

    return $base.Trim()
}