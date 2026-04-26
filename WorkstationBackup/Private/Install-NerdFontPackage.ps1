function Install-NerdFontPackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FontName
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Get-Command -Name 'Install-NerdFont' -ErrorAction SilentlyContinue)) {
        throw 'Install-NerdFont command is not available after importing NerdFonts.'
    }

    $installParameters = @{
        Name = $FontName
    }

    if ($Config.Fonts.PSObject.Properties.Name.Contains('Scope') -and -not [string]::IsNullOrWhiteSpace($Config.Fonts.Scope)) {
        $installParameters.Scope = $Config.Fonts.Scope
    }

    Write-BackupLog -Message "Installing Nerd Font '$FontName'"

    if ($PSCmdlet.ShouldProcess("Nerd Font $FontName", 'Install font')) {
        Install-NerdFont @installParameters
    }
}