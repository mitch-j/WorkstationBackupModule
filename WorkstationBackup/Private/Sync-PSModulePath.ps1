function Sync-PSModulePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $preferred = @(
        $Config.PersonalModulesPath,
        $Config.ExternalModulesPath
    )

    foreach ($path in $preferred) {
        Ensure-Directory -Path $path
    }

    $existing = $env:PSModulePath -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -and
            $_ -notin $preferred -and
            $_ -notmatch 'OneDrive.*Documents\\PowerShell\\Modules' -and
            $_ -notmatch 'Documents\\PowerShell\\Modules'
        } |
        Select-Object -Unique

    $env:PSModulePath = (@($preferred) + @($existing)) -join ';'
    Write-BackupLog -Message ('PSModulePath synchronized. Preferred paths: {0}' -f ($preferred -join ', '))
}