function Get-SiteName {
<#
.SYNOPSIS
This function will use the DsGetSiteName Win32API call to look up the
name of the site where a specified computer resides.

.DESCRIPTION
This function will use the DsGetSiteName Win32API call to look up the
name of the site where a specified computer resides.

.PARAMETER ComputerName

The hostname to look the site up for, default to localhost.

.EXAMPLE

PS C:\> Get-SiteName -ComputerName WINDOWS1

Returns the site for WINDOWS1.testlab.local.

.EXAMPLE

PS C:\> Get-NetComputer | Get-SiteName

Returns the sites for every machine in AD.
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = $Env:ComputerName
    )

    # extract the computer name from whatever object was passed on the pipeline
    $Computer = $ComputerName | Get-NameField

    # if we get an IP address, try to resolve the IP to a hostname
    if($Computer -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
        $IPAddress = $Computer
        $Computer = [System.Net.Dns]::GetHostByAddress($Computer)
    }
    else {
        $IPAddress = @(Get-IPAddress -ComputerName $Computer)[0].IPAddress
    }

    $PtrInfo = [IntPtr]::Zero

    $Result = $Netapi32::DsGetSiteName($Computer, [ref]$PtrInfo)

    $ComputerSite = New-Object PSObject
    $ComputerSite | Add-Member Noteproperty 'ComputerName' $Computer
    $ComputerSite | Add-Member Noteproperty 'IPAddress' $IPAddress

    if ($Result -eq 0) {
        $Sitename = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($PtrInfo)
        $ComputerSite | Add-Member Noteproperty 'SiteName' $Sitename
    }
    else {
        $ErrorMessage = "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
        $ComputerSite | Add-Member Noteproperty 'SiteName' $ErrorMessage
    }

    $Null = $Netapi32::NetApiBufferFree($PtrInfo)

    $ComputerSite
}