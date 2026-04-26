function Get-InstalledGalleryModuleRecords {
    [CmdletBinding()]
    param()

    $records = @()

    $powerShellGet = Get-Module -ListAvailable -Name PowerShellGet | Sort-Object Version -Descending | Select-Object -First 1
    if ($powerShellGet) {
        Import-Module -Name $powerShellGet.Path -ErrorAction SilentlyContinue | Out-Null
    }

    if (Get-Command -Name Get-InstalledModule -ErrorAction SilentlyContinue) {
        try {
            $records = @(Get-InstalledModule -ErrorAction Stop | Sort-Object Name, Version)
        }
        catch {
            Write-BackupLog -Level WARN -Message "Get-InstalledModule failed, continuing with empty gallery manifest: $($_.Exception.Message)"
            $records = @()
        }
    }

    return $records
}