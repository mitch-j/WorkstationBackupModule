function Test-RequiredCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Required command '$CommandName' was not found in PATH."
    }

    return $true
}
