function Get-DomainSID {
<#
.SYNOPSIS
Gets the SID for the domain.

.DESCRIPTION
Gets the SID for the domain.

.PARAMETER Domain
The domain to query, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.EXAMPLE
C:\> Get-DomainSID -Domain TEST

Returns SID for the domain 'TEST'
#>

    param(
        [String]
        $Domain,

        [String]
        $DomainController
    )

    $DCSID = Get-NetComputer -Domain $Domain -DomainController $DomainController -FullData -Filter '(userAccountControl:1.2.840.113556.1.4.803:=8192)' | Select-Object -First 1 -ExpandProperty objectsid
    if($DCSID) {
        $DCSID.Substring(0, $DCSID.LastIndexOf('-'))
    }
    else {
        Write-Verbose "Error extracting domain SID for $Domain"
    }
}