function Get-DNSZone {
<#
.SYNOPSIS
Enumerates the Active Directory DNS zones for a given domain.

.DESCRIPTION
Enumerates the Active Directory DNS zones for a given domain.

.PARAMETER Domain

The domain to query for zones, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER PageSize

The PageSize to set for the LDAP searcher object.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.PARAMETER FullData

Switch. Return full computer objects instead of just system names (the default).

.EXAMPLE

PS C:\> Get-DNSZone

Retrieves the DNS zones for the current domain.

.EXAMPLE

PS C:\> Get-DNSZone -Domain dev.testlab.local -DomainController primary.testlab.local

Retrieves the DNS zones for the dev.testlab.local domain, reflecting the LDAP queries
through the primary.testlab.local domain controller.
#>

    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)]
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential,

        [Switch]
        $FullData
    )

    $DNSSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential
    $DNSSearcher.filter="(objectClass=dnsZone)"

    if($DNSSearcher) {
        $Results = $DNSSearcher.FindAll()
        $Results | Where-Object {$_} | ForEach-Object {
            # convert/process the LDAP fields for each result
            $Properties = Convert-LDAPProperty -Properties $_.Properties
            $Properties | Add-Member NoteProperty 'ZoneName' $Properties.name

            if ($FullData) {
                $Properties
            }
            else {
                $Properties | Select-Object ZoneName,distinguishedname,whencreated,whenchanged
            }
        }
        $Results.dispose()
        $DNSSearcher.dispose()
    }

    $DNSSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -PageSize $PageSize -Credential $Credential -ADSprefix "CN=MicrosoftDNS,DC=DomainDnsZones"
    $DNSSearcher.filter="(objectClass=dnsZone)"

    if($DNSSearcher) {
        $Results = $DNSSearcher.FindAll()
        $Results | Where-Object {$_} | ForEach-Object {
            # convert/process the LDAP fields for each result
            $Properties = Convert-LDAPProperty -Properties $_.Properties
            $Properties | Add-Member NoteProperty 'ZoneName' $Properties.name

            if ($FullData) {
                $Properties
            }
            else {
                $Properties | Select-Object ZoneName,distinguishedname,whencreated,whenchanged
            }
        }
        $Results.dispose()
        $DNSSearcher.dispose()
    }
}