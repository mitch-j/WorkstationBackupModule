function Get-NerdFontCandidatesFromLegacyConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($item in @($Config.Fonts.Files)) {
        if ($null -eq $item) {
            continue
        }

        $candidate = $null

        if ($item.PSObject.Properties.Name.Contains('FontName') -and -not [string]::IsNullOrWhiteSpace($item.FontName)) {
            $candidate = $item.FontName -replace '\s+Nerd Font.*$', ''
            $candidate = $candidate -replace '\s+', ''
        }
        elseif ($item.PSObject.Properties.Name.Contains('Source') -and -not [string]::IsNullOrWhiteSpace($item.Source)) {
            $leaf = [System.IO.Path]::GetFileNameWithoutExtension($item.Source)
            $candidate = $leaf -replace '-(Thin|ThinItalic|ExtraLight|ExtraLightItalic|Light|LightItalic|Regular|Italic|Medium|MediumItalic|SemiBold|SemiBoldItalic|Bold|BoldItalic|ExtraBold|ExtraBoldItalic|Black|BlackItalic|SemiLight|SemiLightItalic)$', ''
            $candidate = $candidate -replace 'NerdFontMono$', ''
            $candidate = $candidate -replace 'NerdFontPropo$', ''
            $candidate = $candidate -replace 'NerdFont$', ''
        }

        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            [void]$candidates.Add($candidate)
        }
    }

    return @($candidates | Sort-Object -Unique)
}