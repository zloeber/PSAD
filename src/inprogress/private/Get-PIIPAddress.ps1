function Get-PIIPAddress {
    # Retreive IP address informaton from dot net core only functions (should run on both linux and windows properly)
    $NetworkInterfaces = @([System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {($_.OperationalStatus -eq 'Up')})
    $NetworkInterfaces | Foreach-Object {
        $_.GetIPProperties() | Where-Object {$_.GatewayAddresses} | Foreach-Object {
            $Gateway = $_.GatewayAddresses.Address.IPAddressToString
            $DNSAddresses = @($_.DnsAddresses | Foreach-Object {$_.IPAddressToString})
            $_.UnicastAddresses | Where-Object {$_.Address -notlike '*::*'} | Foreach-Object {
                New-Object PSObject -Property @{
                    IP = $_.Address
                    Prefix = $_.PrefixLength
                    Gateway = $Gateway
                    DNS = $DNSAddresses
                }
            }
        }
    }
}
