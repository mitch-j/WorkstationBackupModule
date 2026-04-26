function New-BackupFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prefix,

        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [string]$Extension,

        [Parameter()]
        [datetime]$Date = (Get-Date)
    )

    $dateStamp = $Date.ToString('yyyy-MM-dd')
    $normalizedExtension = if ($Extension.StartsWith('.')) { $Extension } else { ".{0}" -f $Extension }

    return '{0}-{1}-{2}{3}' -f $Prefix, $HostName.Trim(), $dateStamp, $normalizedExtension
}
