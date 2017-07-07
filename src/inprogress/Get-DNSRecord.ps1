function Get-DNSRecord {
<#
.SYNOPSIS
Enumerates the Active Directory DNS records for a given zone.

.DESCRIPTION
Enumerates the Active Directory DNS records for a given zone.

.PARAMETER ZoneName

The zone to query for records (which can be enumearted with Get-DNSZone). Required.

.PARAMETER Domain

The domain to query for zones, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER PageSize

The PageSize to set for the LDAP searcher object.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

PS C:\> Get-DNSRecord -ZoneName testlab.local

Retrieve all records for the testlab.local zone.

.EXAMPLE

PS C:\> Get-DNSZone | Get-DNSRecord

Retrieve all records for all zones in the current domain.

.EXAMPLE

PS C:\> Get-DNSZone -Domain dev.testlab.local | Get-DNSRecord -Domain dev.testlab.local

Retrieve all records for all zones in the dev.testlab.local domain.
#>

    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
        [String]
        $ZoneName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)]
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    $DNSSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential -ADSprefix "DC=$($ZoneName),CN=MicrosoftDNS,DC=DomainDnsZones"
    $DNSSearcher.filter="(objectClass=dnsNode)"

    if($DNSSearcher) {
        $Results = $DNSSearcher.FindAll()
        $Results | Where-Object {$_} | ForEach-Object {
            try {
                # convert/process the LDAP fields for each result
                $Properties = Convert-LDAPProperty -Properties $_.Properties | Select-Object name,distinguishedname,dnsrecord,whencreated,whenchanged
                $Properties | Add-Member NoteProperty 'ZoneName' $ZoneName

                # convert the record and extract the properties
                if ($Properties.dnsrecord -is [System.DirectoryServices.ResultPropertyValueCollection]) {
                    # TODO: handle multiple nested records properly?
                    $Record = Convert-DNSRecord -DNSRecord $Properties.dnsrecord[0]
                }
                else {
                    $Record = Convert-DNSRecord -DNSRecord $Properties.dnsrecord
                }

                if($Record) {
                    $Record.psobject.properties | ForEach-Object {
                        $Properties | Add-Member NoteProperty $_.Name $_.Value
                    }
                }

                $Properties
            }
            catch {
                Write-Warning "ERROR: $_"
                $Properties
            }
        }
        $Results.dispose()
        $DNSSearcher.dispose()
    }
}