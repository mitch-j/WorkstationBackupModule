function Resolve-BackupPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $resolvedPath = $Path

    $specialTokens = @{
        '{CurrentUserCurrentHostProfile}' = $PROFILE.CurrentUserCurrentHost
        '{CurrentUserAllHostsProfile}'    = $PROFILE.CurrentUserAllHosts
        '{UserProfile}'                   = $env:USERPROFILE
        '{AppData}'                       = $env:APPDATA
        '{LocalAppData}'                  = $env:LOCALAPPDATA
    }

    foreach ($token in $specialTokens.Keys) {
        if ($resolvedPath -like "*$token*") {
            $resolvedPath = $resolvedPath.Replace($token, $specialTokens[$token])
        }
    }

    $resolvedPath = [Environment]::ExpandEnvironmentVariables($resolvedPath)

    return $resolvedPath
}