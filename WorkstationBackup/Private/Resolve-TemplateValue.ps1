function Resolve-TemplateValue {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [string]$RelativeRoot
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    $expanded = $Value
    try {
        $expanded = $ExecutionContext.InvokeCommand.ExpandString($expanded)
    }
    catch {
        # Leave value unchanged when expansion fails.
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($expanded)

    if ([string]::IsNullOrWhiteSpace($expanded)) {
        return $expanded
    }

    if ($RelativeRoot -and -not [System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath((Join-Path $RelativeRoot $expanded))
    }

    if ([System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath($expanded)
    }

    return $expanded
}