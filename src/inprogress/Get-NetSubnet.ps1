function Get-NetSubnet {
<#
.SYNOPSIS
Gets a list of all current subnets in a domain.

.DESCRIPTION
Gets a list of all current subnets in a domain.

.PARAMETER SiteName
Only return subnets from the specified SiteName.

.PARAMETER Domain
The domain to query for subnets, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER ADSpath
The LDAP source to search through.

.PARAMETER FullData
Switch. Return full subnet objects instead of just object names (the default).

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE
PS C:\> Get-NetSubnet

Returns all subnet names in the current domain.

.EXAMPLE
PS C:\> Get-NetSubnet -Domain testlab.local -FullData

Returns the full data objects for all subnets in testlab.local
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SiteName = "*",

        [String]
        $Domain,

        [String]
        $ADSpath,

        [String]
        $DomainController,

        [Switch]
        $FullData,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $SubnetSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -ADSprefix "CN=Subnets,CN=Sites,CN=Configuration" -PageSize $PageSize
    }

    process {
        if($SubnetSearcher) {

            $SubnetSearcher.filter="(&(objectCategory=subnet))"

            try {
                $Results = $SubnetSearcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    if ($FullData) {
                        # convert/process the LDAP fields for each result
                        Convert-LDAPProperty -Properties $_.Properties | Where-Object { $_.siteobject -match "CN=$SiteName" }
                    }
                    else {
                        # otherwise just return the subnet name and site name
                        if ( ($SiteName -and ($_.properties.siteobject -match "CN=$SiteName,")) -or ($SiteName -eq '*')) {

                            $SubnetProperties = @{
                                'Subnet' = $_.properties.name[0]
                            }
                            try {
                                $SubnetProperties['Site'] = ($_.properties.siteobject[0]).split(",")[0]
                            }
                            catch {
                                $SubnetProperties['Site'] = 'Error'
                            }

                            New-Object -TypeName PSObject -Property $SubnetProperties
                        }
                    }
                }
                $Results.dispose()
                $SubnetSearcher.dispose()
            }
            catch {
                Write-Warning $_
            }
        }
    }
}