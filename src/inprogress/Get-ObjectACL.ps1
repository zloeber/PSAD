function Get-ObjectAcl {
<#
.SYNOPSIS
Returns the ACLs associated with a specific active directory object.

.DESCRIPTION
Returns the ACLs associated with a specific active directory object.

.PARAMETER SamAccountName
Object name to filter for.

.PARAMETER Name
Object name to filter for.

.PARAMETER DistinguishedName
Object distinguished name to filter for.

.PARAMETER ResolveGUIDs
Switch. Resolve GUIDs to their display names.

.PARAMETER Filter
A customized ldap filter string to use, e.g. "(description=*admin*)"

.PARAMETER ADSpath
The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER ADSprefix
Prefix to set for the searcher (like "CN=Sites,CN=Configuration")

.PARAMETER RightsFilter
Only return results with the associated rights, "All", "ResetPassword","WriteMembers"

.PARAMETER Domain
The domain to use for the query, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.EXAMPLE

PS C:\> Get-ObjectAcl -SamAccountName matt.admin -domain testlab.local

Get the ACLs for the matt.admin user in the testlab.local domain

.EXAMPLE

PS C:\> Get-ObjectAcl -SamAccountName matt.admin -domain testlab.local -ResolveGUIDs

Get the ACLs for the matt.admin user in the testlab.local domain and
resolve relevant GUIDs to their display names.

.EXAMPLE

PS C:\> Get-NetOU -FullData | Get-ObjectAcl -ResolveGUIDs

Enumerate the ACL permissions for all OUs in the domain.

.NOTES
Thanks Sean Metcalf (@pyrotek3) for the idea and guidance.

#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $SamAccountName,

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $Name = "*",

        [Parameter(ValueFromPipelineByPropertyName=$True)]
        [String]
        $DistinguishedName = "*",

        [Switch]
        $ResolveGUIDs,

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        [ValidateSet("All","ResetPassword","WriteMembers")]
        $RightsFilter,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)]
        [Int]
        $PageSize = 200
    )

    begin {
        $Searcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -ADSprefix $ADSprefix -PageSize $PageSize

        # get a GUID -> name mapping
        if($ResolveGUIDs) {
            $GUIDs = Get-GUIDMap -Domain $Domain -DomainController $DomainController -PageSize $PageSize
        }
    }

    process {

        if ($Searcher) {

            if($SamAccountName) {
                $Searcher.filter="(&(samaccountname=$SamAccountName)(name=$Name)(distinguishedname=$DistinguishedName)$Filter)"
            }
            else {
                $Searcher.filter="(&(name=$Name)(distinguishedname=$DistinguishedName)$Filter)"
            }

            try {
                $Results = $Searcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {
                    $Object = [adsi]($_.path)

                    if($Object.distinguishedname) {
                        $Access = $Object.PsBase.ObjectSecurity.access
                        $Access | ForEach-Object {
                            $_ | Add-Member NoteProperty 'ObjectDN' $Object.distinguishedname[0]

                            if($Object.objectsid[0]){
                                $S = (New-Object System.Security.Principal.SecurityIdentifier($Object.objectsid[0],0)).Value
                            }
                            else {
                                $S = $Null
                            }

                            $_ | Add-Member NoteProperty 'ObjectSID' $S
                            $_
                        }
                    }
                } | ForEach-Object {
                    if($RightsFilter) {
                        $GuidFilter = Switch ($RightsFilter) {
                            "ResetPassword" { "00299570-246d-11d0-a768-00aa006e0529" }
                            "WriteMembers" { "bf9679c0-0de6-11d0-a285-00aa003049e2" }
                            Default { "00000000-0000-0000-0000-000000000000"}
                        }
                        if($_.ObjectType -eq $GuidFilter) { $_ }
                    }
                    else {
                        $_
                    }
                } | ForEach-Object {
                    if($GUIDs) {
                        # if we're resolving GUIDs, map them them to the resolved hash table
                        $AclProperties = @{}
                        $_.psobject.properties | ForEach-Object {
                            if( ($_.Name -eq 'ObjectType') -or ($_.Name -eq 'InheritedObjectType') ) {
                                try {
                                    $AclProperties[$_.Name] = $GUIDS[$_.Value.toString()]
                                }
                                catch {
                                    $AclProperties[$_.Name] = $_.Value
                                }
                            }
                            else {
                                $AclProperties[$_.Name] = $_.Value
                            }
                        }
                        New-Object -TypeName PSObject -Property $AclProperties
                    }
                    else { $_ }
                }
                $Results.dispose()
                $Searcher.dispose()
            }
            catch {
                Write-Warning $_
            }
        }
    }
}
