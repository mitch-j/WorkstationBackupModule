function Resolve-BackupPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    $resolvedPath = $Path

    # Handle $PROFILE literal strings (case-sensitive replacement)
    if ($resolvedPath.Contains('$PROFILE.CurrentUserCurrentHost')) {
        $resolvedPath = $resolvedPath.Replace('$PROFILE.CurrentUserCurrentHost', $PROFILE.CurrentUserCurrentHost)
    }
    elseif ($resolvedPath.Contains('$PROFILE.CurrentUserAllHosts')) {
        $resolvedPath = $resolvedPath.Replace('$PROFILE.CurrentUserAllHosts', $PROFILE.CurrentUserAllHosts)
    }
    elseif ($resolvedPath.Contains('$PROFILE')) {
        $resolvedPath = $resolvedPath.Replace('$PROFILE', $PROFILE)
    }

    # Handle environment variable strings
    $specialTokens = @{
        '{CurrentUserCurrentHostProfile}' = $PROFILE.CurrentUserCurrentHost
        '{CurrentUserAllHostsProfile}'    = $PROFILE.CurrentUserAllHosts
        '{UserProfile}'                   = $env:USERPROFILE
        '{AppData}'                       = $env:APPDATA
        '{LocalAppData}'                  = $env:LOCALAPPDATA
    }

    foreach ($token in $specialTokens.Keys) {
        if ($resolvedPath.Contains($token)) {
            $resolvedPath = $resolvedPath.Replace($token, $specialTokens[$token])
        }
    }

    # Finally, expand any remaining environment variables like $env:POSH_THEMES_PATH
    $resolvedPath = [Environment]::ExpandEnvironmentVariables($resolvedPath)

    return $resolvedPath
}