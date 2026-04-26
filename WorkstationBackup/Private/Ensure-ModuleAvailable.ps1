function Ensure-ModuleAvailable {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [string]$Repository = 'PSGallery',

        [Parameter()]
        [switch]$ImportOnly,

        [Parameter()]
        [switch]$AllowFailure
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $module = Get-Module -ListAvailable -Name $Name |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if (-not $module -and -not $ImportOnly) {
        Write-BackupLog -Message "Module '$Name' not found locally. Attempting install from repository '$Repository'."

        try {
            if ($PSCmdlet.ShouldProcess("PowerShell module $Name", "Install from repository $Repository")) {
                Install-Module `
                    -Name $Name `
                    -Repository $Repository `
                    -Scope CurrentUser `
                    -Force `
                    -AllowClobber `
                    -ErrorAction Stop
            }
        }
        catch {
            if ($AllowFailure) {
                Write-BackupLog -Level 'WARN' -Message "Failed to install module '$Name': $($_.Exception.Message)"
                return $false
            }

            throw
        }

        $module = Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1
    }

    if (-not $module) {
        if ($AllowFailure) {
            Write-BackupLog -Level 'WARN' -Message "Module '$Name' is not available."
            return $false
        }

        throw "Module '$Name' is not available."
    }

    try {
        Import-Module -Name $module.Path -Force -ErrorAction Stop | Out-Null
        Write-BackupLog -Message "Module '$Name' is available and imported."
        return $true
    }
    catch {
        if ($AllowFailure) {
            Write-BackupLog -Level 'WARN' -Message "Failed to import module '$Name': $($_.Exception.Message)"
            return $false
        }

        throw
    }
}