function Restore-NerdFonts {
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
        Write-BackupLog -Message 'Skipping font install because InstallOnApply is disabled.'
        return
    }

    $requiredFonts = @(Get-DesiredNerdFontFamily -Config $Config)
    if ($requiredFonts.Count -eq 0) {
        Write-BackupLog -Message 'No required Nerd Fonts are configured. Skipping font install.'
        return
    }

    $providerReady = Initialize-FontRestorePrerequisite `
        -Config $Config `
        -SkipFontInstallFailures:$SkipFontInstallFailures `
        -WhatIf:$WhatIfPreference

    if (-not $providerReady) {
        Write-BackupLog -Level 'WARN' -Message 'Font provider prerequisites are not available. Skipping font install.'
        return
    }

    if (-not (Get-Command -Name 'Get-NerdFont' -ErrorAction SilentlyContinue)) {
        $message = 'Get-NerdFont command is not available after importing NerdFonts.'
        if ($SkipFontInstallFailures) {
            Write-BackupLog -Level 'WARN' -Message $message
            return
        }

        throw $message
    }

    $available = @(Get-AvailableNerdFont -Config $Config)
    $installed = @(Get-InstalledNerdFontFamily -Config $Config)

    foreach ($fontName in $requiredFonts) {
        if ($fontName -in $installed) {
            Write-BackupLog -Message "Nerd Font already installed: $fontName"
            continue
        }

        if ($fontName -notin $available) {
            $message = "Configured Nerd Font '$fontName' is not recognized by Get-NerdFont."
            if ($SkipFontInstallFailures) {
                Write-BackupLog -Level 'WARN' -Message $message
                continue
            }

            throw $message
        }

        try {
            Install-NerdFontPackage -Config $Config -FontName $fontName -WhatIf:$WhatIfPreference
        }
        catch {
            if ($SkipFontInstallFailures) {
                Write-BackupLog -Level 'WARN' -Message "Failed to install Nerd Font '$fontName': $($_.Exception.Message)"
                continue
            }

            throw
        }
    }
}