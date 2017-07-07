function Invoke-ACLScanner {
<#
.SYNOPSIS
Searches for ACLs for specifable AD objects (default to all domain objects)
with a domain sid of > -1000, and have modifiable rights.

.DESCRIPTION
Searches for ACLs for specifable AD objects (default to all domain objects)
with a domain sid of > -1000, and have modifiable rights.

.PARAMETER SamAccountName

Object name to filter for.        

.PARAMETER Name

Object name to filter for.

.PARAMETER DistinguishedName

Object distinguished name to filter for.

.PARAMETER Filter

A customized ldap filter string to use, e.g. "(description=*admin*)"

.PARAMETER ADSpath

The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER ADSprefix

Prefix to set for the searcher (like "CN=Sites,CN=Configuration")

.PARAMETER Domain

The domain to use for the query, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER ResolveGUIDs

Switch. Resolve GUIDs to their display names.

.PARAMETER PageSize

The PageSize to set for the LDAP searcher object.

.EXAMPLE

PS C:\> Invoke-ACLScanner -ResolveGUIDs | Export-CSV -NoTypeInformation acls.csv

Enumerate all modifable ACLs in the current domain, resolving GUIDs to display 
names, and export everything to a .csv

.NOTES
Thanks Sean Metcalf (@pyrotek3) for the idea and guidance.

#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SamAccountName,

        [String]
        $Name = "*",

        [Alias('DN')]
        [String]
        $DistinguishedName = "*",

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $ResolveGUIDs,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    # Get all domain ACLs with the appropriate parameters
    Get-ObjectACL @PSBoundParameters | ForEach-Object {
        # add in the translated SID for the object identity
        $_ | Add-Member Noteproperty 'IdentitySID' ($_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value)
        $_
    } | Where-Object {
        # check for any ACLs with SIDs > -1000
        try {
            # TODO: change this to a regex for speedup?
            [int]($_.IdentitySid.split("-")[-1]) -ge 1000
        }
        catch {}
    } | Where-Object {
        # filter for modifiable rights
        ($_.ActiveDirectoryRights -eq "GenericAll") -or ($_.ActiveDirectoryRights -match "Write") -or ($_.ActiveDirectoryRights -match "Create") -or ($_.ActiveDirectoryRights -match "Delete") -or (($_.ActiveDirectoryRights -match "ExtendedRight") -and ($_.AccessControlType -eq "Allow"))
    }
}