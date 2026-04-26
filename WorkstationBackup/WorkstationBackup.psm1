Set-StrictMode -Version Latest

$publicPath = Join-Path $PSScriptRoot 'Public'
$privatePath = Join-Path $PSScriptRoot 'Private'

foreach ($path in @($privatePath, $publicPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }

    Get-ChildItem -LiteralPath $path -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object {
            . $_.FullName
        }
}

$publicFunctions = Get-ChildItem -LiteralPath $publicPath -Filter '*.ps1' -File |
    Select-Object -ExpandProperty BaseName

Export-ModuleMember -Function $publicFunctions
