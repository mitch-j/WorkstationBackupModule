function Get-WorkstationBackupRoot {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$RepoRoot,

        [Parameter()]
        [string]$ScriptPath,

        [Parameter()]
        [string]$ModuleRoot = $PSScriptRoot
    )

    if ($RepoRoot) {
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RepoRoot)
    }

    if ($ScriptPath) {
        $scriptDirectory = Split-Path -Path $ScriptPath -Parent
        return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
            (Split-Path -Path $scriptDirectory -Parent)
        )
    }

    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
        (Split-Path -Path $ModuleRoot -Parent)
    )
}
