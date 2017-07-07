function Request-SPNTicket {
<#
.SYNOPSIS
Request the kerberos ticket for a specified service principal name (SPN).

.DESCRIPTION
Request the kerberos ticket for a specified service principal name (SPN).

.PARAMETER SPN
The service principal name to request the ticket for. Required.

.PARAMETER EncPart
Switch. Return the encrypted portion of the ticket (cipher).

.EXAMPLE
PS C:\> Request-SPNTicket -SPN "HTTP/web.testlab.local"

Request a kerberos service ticket for the specified SPN.

.EXAMPLE
PS C:\> Request-SPNTicket -SPN "HTTP/web.testlab.local" -EncPart

Request a kerberos service ticket for the specified SPN and return the encrypted portion of the ticket.

.EXAMPLE
PS C:\> "HTTP/web1.testlab.local","HTTP/web2.testlab.local" | Request-SPNTicket

Request kerberos service tickets for all SPNs passed on the pipeline.

.EXAMPLE
PS C:\> Get-NetUser -SPN | Request-SPNTicket

Request kerberos service tickets for all users with non-null SPNs.
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $True)]
        [Alias('ServicePrincipalName')]
        [String[]]
        $SPN,
        
        [Alias('EncryptedPart')]
        [Switch]
        $EncPart
    )

    begin {
        Add-Type -AssemblyName System.IdentityModel
    }

    process {
        ForEach($UserSPN in $SPN) {
            Write-Verbose "Requesting ticket for: $UserSPN"
            if (!$EncPart) {
                New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $UserSPN
            }
            else {
                $Ticket = New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList $UserSPN
                $TicketByteStream = $Ticket.GetRequest()
                if ($TicketByteStream)
                {
                    $TicketHexStream = [System.BitConverter]::ToString($TicketByteStream) -replace "-"
                    [System.Collections.ArrayList]$Parts = ($TicketHexStream -replace '^(.*?)04820...(.*)','$2') -Split "A48201"
                    $Parts.RemoveAt($Parts.Count - 1)
                    $Parts -join "A48201"
                    break
                }
            }
        }
    }
}