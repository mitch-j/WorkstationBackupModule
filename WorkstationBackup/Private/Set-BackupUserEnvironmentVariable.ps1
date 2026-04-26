function Set-BackupUserEnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [ValidateSet('User', 'Machine', 'Process')]
        [string]$Scope = 'User'
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $current = [Environment]::GetEnvironmentVariable($Name, $Scope)
    if ($current -eq $Value) {
        Write-BackupLog -Message "Environment variable '$Name' already set for scope '$Scope'."
        return
    }

    if ($PSCmdlet.ShouldProcess("$Scope environment variable $Name", "Set value to '$Value'")) {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)

        if ($Scope -eq 'User' -or $Scope -eq 'Machine' -or $Scope -eq 'Process') {
            Set-Item -Path "Env:$Name" -Value $Value
        }

        Write-BackupLog -Message "Set environment variable '$Name' for scope '$Scope'."
    }
}