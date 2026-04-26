function Initialize-FontRestorePrerequisites {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter()]
        [switch]$SkipFontInstallFailures
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $Config.Fonts.InstallOnApply) {
        return $true
    }

    $provider = if ($Config.Fonts.Provider) { [string]$Config.Fonts.Provider } else { 'NerdFonts' }

    switch ($provider) {
        'NerdFonts' {
            $repository = if ($Config.DefaultRepository) { $Config.DefaultRepository } else { 'PSGallery' }

            $fontsReady = Ensure-ModuleAvailable `
                -Name 'Fonts' `
                -Repository $repository `
                -AllowFailure:$SkipFontInstallFailures `
                -WhatIf:$WhatIfPreference

            $nerdFontsReady = Ensure-ModuleAvailable `
                -Name 'NerdFonts' `
                -Repository $repository `
                -AllowFailure:$SkipFontInstallFailures `
                -WhatIf:$WhatIfPreference

            return ($fontsReady -and $nerdFontsReady)
        }

        default {
            $message = "Unknown font provider '$provider'. Font restore will be skipped."

            if ($SkipFontInstallFailures) {
                Write-BackupLog -Level 'WARN' -Message $message
                return $false
            }

            throw $message
        }
    }
}