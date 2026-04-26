function Get-WorkstationIdentity {
    [CmdletBinding()]
    param()

    $hostName = if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
        [System.Environment]::MachineName
    }
    else {
        $env:COMPUTERNAME
    }

    [pscustomobject]@{
        ComputerName = $hostName
        UserName     = $env:USERNAME
        TimeStamp    = Get-Date
        DateStamp    = Get-Date -Format 'yyyy-MM-dd'
    }
}
