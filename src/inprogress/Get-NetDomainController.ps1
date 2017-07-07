function Get-NetDomainController {
<#
.SYNOPSIS
Return the current domain controllers for the active domain.

.DESCRIPTION
Return the current domain controllers for the active domain.

.PARAMETER Domain

The domain to query for domain controllers, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER LDAP

Switch. Use LDAP queries to determine the domain controllers.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

PS C:\> Get-NetDomainController -Domain 'test.local'

Determine the domain controllers for 'test.local'.

.EXAMPLE

PS C:\> Get-NetDomainController -Domain 'test.local' -LDAP

Determine the domain controllers for 'test.local' using LDAP queries.

.EXAMPLE

PS C:\> 'test.local' | Get-NetDomainController

Determine the domain controllers for 'test.local'.
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $LDAP,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($LDAP -or $DomainController) {
        # filter string to return all domain controllers
        Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -Filter '(userAccountControl:1.2.840.113556.1.4.803:=8192)'
    }
    else {
        $FoundDomain = Get-NetDomain -Domain $Domain -Credential $Credential
        if($FoundDomain) {
            $Founddomain.DomainControllers
        }
    }
}
