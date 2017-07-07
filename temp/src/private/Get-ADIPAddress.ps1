function Get-ADIPAddress {
    [CmdletBinding()]
    [OutputType([string[]])]
    Param (
        # Computer name or FQDN to resolve
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        $ComputerName
    )

    Process {
        try {
            $IPArray = ([Net.Dns]::GetHostEntry($ComputerName)).AddressList
            foreach ($IPa in $IPArray) {
                $IPa.IPAddressToString
            }
        }
        catch {
            Write-Verbose -Message "Could not resolve $($computerName)"
        }
    }
}
