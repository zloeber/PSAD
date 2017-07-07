function Get-NetUser {
<#
.SYNOPSIS
Query information for a given user or users in the domain using ADSI and LDAP. Another -Domain can be specified to query for users across a trust. 
Replacement for "net users /domain"

.DESCRIPTION
Query information for a given user or users in the domain using ADSI and LDAP. Another -Domain can be specified to query for users across a trust. 
Replacement for "net users /domain"

.PARAMETER UserName
Username filter string, wildcards accepted.

.PARAMETER Domain
The domain to query for users, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER ADSpath
The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER Filter
A customized ldap filter string to use, e.g. "(description=*admin*)"

.PARAMETER AdminCount
Switch. Return users with adminCount=1.

.PARAMETER SPN
Switch. Only return user objects with non-null service principal names.

.PARAMETER Unconstrained
Switch. Return users that have unconstrained delegation.

.PARAMETER AllowDelegation
Switch. Return user accounts that are not marked as 'sensitive and not allowed for delegation'

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials for connection to the target domain.

.EXAMPLE
PS C:\> Get-NetUser -Domain testing

.EXAMPLE
PS C:\> Get-NetUser -ADSpath "LDAP://OU=secret,DC=testlab,DC=local"
#>

    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [String]
        $UserName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $Filter,

        [Switch]
        $SPN,

        [Switch]
        $AdminCount,

        [Switch]
        $Unconstrained,

        [Switch]
        $AllowDelegation,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        # so this isn't repeated if users are passed on the pipeline
        $UserSearcher = Get-DomainSearcher -Domain $Domain -ADSpath $ADSpath -DomainController $DomainController -PageSize $PageSize -Credential $Credential
    }

    process {
        if($UserSearcher) {

            # if we're checking for unconstrained delegation
            if($Unconstrained) {
                Write-Verbose "Checking for unconstrained delegation"
                $Filter += "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
            }
            if($AllowDelegation) {
                Write-Verbose "Checking for users who can be delegated"
                # negation of "Accounts that are sensitive and not trusted for delegation"
                $Filter += "(!(userAccountControl:1.2.840.113556.1.4.803:=1048574))"
            }
            if($AdminCount) {
                Write-Verbose "Checking for adminCount=1"
                $Filter += "(admincount=1)"
            }

            # check if we're using a username filter or not
            if($UserName) {
                # samAccountType=805306368 indicates user objects
                $UserSearcher.filter="(&(samAccountType=805306368)(samAccountName=$UserName)$Filter)"
            }
            elseif($SPN) {
                $UserSearcher.filter="(&(samAccountType=805306368)(servicePrincipalName=*)$Filter)"
            }
            else {
                # filter is something like "(samAccountName=*blah*)" if specified
                $UserSearcher.filter="(&(samAccountType=805306368)$Filter)"
            }

            $Results = $UserSearcher.FindAll()
            $Results | Where-Object {$_} | ForEach-Object {
                # convert/process the LDAP fields for each result
                $User = Convert-LDAPProperty -Properties $_.Properties
                $User.PSObject.TypeNames.Add('PowerView.User')
                $User
            }
            $Results.dispose()
            $UserSearcher.dispose()
        }
    }
}