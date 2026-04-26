function Get-NerdFontStyleSuffixPattern {
    [CmdletBinding()]
    param()

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    return 'Thin|ThinItalic|ExtraLight|ExtraLightItalic|Light|LightItalic|Regular|Italic|Medium|MediumItalic|SemiBold|SemiBoldItalic|Bold|BoldItalic|ExtraBold|ExtraBoldItalic|Black|BlackItalic|SemiLight|SemiLightItalic'
}