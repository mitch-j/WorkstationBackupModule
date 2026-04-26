function Get-InstalledNerdFontFamilies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    try {
        if (-not (Ensure-ModuleAvailable -Name 'Fonts' -Repository $Config.DefaultRepository -ImportOnly -AllowFailure)) {
            Write-BackupLog -Level 'WARN' -Message 'Fonts module is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        if (-not (Get-Command -Name 'Get-Font' -ErrorAction SilentlyContinue)) {
            Write-BackupLog -Level 'WARN' -Message 'Get-Font command is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        $fontObjects = @(Get-Font)
        if ($fontObjects.Count -eq 0) {
            return @()
        }

        $nameProperty = $null
        $candidateProperties = @('FullName', 'Name', 'FontName', 'Family', 'FamilyName')

        foreach ($property in $candidateProperties) {
            if ($fontObjects[0].PSObject.Properties.Name -contains $property) {
                $nameProperty = $property
                break
            }
        }

        if (-not $nameProperty) {
            Write-BackupLog -Level 'WARN' -Message ('Unable to determine font name property from Get-Font output. Available properties: {0}' -f (($fontObjects[0].PSObject.Properties.Name | Sort-Object) -join ', '))
            return @()
        }

        $installedFontNames = @(
            $fontObjects |
            ForEach-Object { $_.$nameProperty } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }
    catch {
        Write-BackupLog -Level 'WARN' -Message "Failed to enumerate installed fonts: $($_.Exception.Message)"
        return @()
    }

    $availableNames = @()
    try {
        if (-not (Ensure-ModuleAvailable -Name 'NerdFonts' -Repository $Config.DefaultRepository -ImportOnly -AllowFailure)) {
            Write-BackupLog -Level 'WARN' -Message 'NerdFonts module is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        if (-not (Get-Command -Name 'Get-NerdFont' -ErrorAction SilentlyContinue)) {
            Write-BackupLog -Level 'WARN' -Message 'Get-NerdFont command is not available. Installed Nerd Font discovery will be skipped.'
            return @()
        }

        $availableNames = @(Get-NerdFont | Select-Object -ExpandProperty Name)
    }
    catch {
        Write-BackupLog -Level 'WARN' -Message "Failed to enumerate available NerdFonts names: $($_.Exception.Message)"
        return @()
    }

    $families = foreach ($name in $installedFontNames) {
        $candidate = Convert-InstalledFontNameToNerdFontCandidate -Name ([string]$name)
        if ($candidate -and $candidate -in $availableNames) {
            $candidate
        }
    }

    return @($families | Sort-Object -Unique)
}