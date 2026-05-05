function Resolve-TemplateValue {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [string]$RelativeRoot,

        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    $expanded = $Value
    
    # Replace {ComputerName} placeholder
    if ($expanded.Contains('{ComputerName}')) {
        $expanded = $expanded.Replace('{ComputerName}', $ComputerName)
    }
    
    try {
        $expanded = $ExecutionContext.InvokeCommand.ExpandString($expanded)
    }
    catch {
        Write-BackupLog -Level WARN -Message "Template expansion failed for value: $Value"
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