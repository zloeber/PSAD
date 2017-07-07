function Find-ForeignUser {
<#
.SYNOPSIS
Enumerates users who are in groups outside of their principal domain.

.DESCRIPTION
Enumerates users who are in groups outside of their principal domain.

.PARAMETER UserName
Username to filter results for, wildcards accepted.

.PARAMETER Domain
Domain to query for users, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER LDAP
Switch. Use LDAP queries to enumerate the trusts instead of direct domain connections.
More likely to get around network segmentation, but not as accurate.

.PARAMETER Recurse
Try to map all transitive domain trust relationships and enumerate all users who are in groups outside of their principal domain.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.EXAMPLE
TBD

.LINK
http://blog.harmj0y.net/
#>

    [CmdletBinding()]
    param(
        [String]
        $UserName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $LDAP,

        [Switch]
        $Recurse,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    function Get-ForeignUser {
        # helper used to enumerate users who are in groups outside of their principal domain
        param(
            [String]
            $UserName,

            [String]
            $Domain,

            [String]
            $DomainController,

            [ValidateRange(1,10000)] 
            [Int]
            $PageSize = 200
        )

        if ($Domain) {
            # get the domain name into distinguished form
            $DistinguishedDomainName = "DC=" + $Domain -replace '\.',',DC='
        }
        else {
            $DistinguishedDomainName = [String] ([adsi]'').distinguishedname
            $Domain = $DistinguishedDomainName -replace 'DC=','' -replace ',','.'
        }

        Get-NetUser -Domain $Domain -DomainController $DomainController -UserName $UserName -PageSize $PageSize -Filter '(memberof=*)' | ForEach-Object {
            ForEach ($Membership in $_.memberof) {
                $Index = $Membership.IndexOf("DC=")
                if($Index) {
                    
                    $GroupDomain = $($Membership.substring($Index)) -replace 'DC=','' -replace ',','.'
                    
                    if ($GroupDomain.CompareTo($Domain)) {
                        # if the group domain doesn't match the user domain, output
                        $GroupName = $Membership.split(",")[0].split("=")[1]
                        $ForeignUser = New-Object PSObject
                        $ForeignUser | Add-Member Noteproperty 'UserDomain' $Domain
                        $ForeignUser | Add-Member Noteproperty 'UserName' $_.samaccountname
                        $ForeignUser | Add-Member Noteproperty 'GroupDomain' $GroupDomain
                        $ForeignUser | Add-Member Noteproperty 'GroupName' $GroupName
                        $ForeignUser | Add-Member Noteproperty 'GroupDN' $Membership
                        $ForeignUser
                    }
                }
            }
        }
    }

    if ($Recurse) {
        # get all rechable domains in the trust mesh and uniquify them
        if($LDAP -or $DomainController) {
            $DomainTrusts = Invoke-MapDomainTrust -LDAP -DomainController $DomainController -PageSize $PageSize | ForEach-Object { $_.SourceDomain } | Sort-Object -Unique
        }
        else {
            $DomainTrusts = Invoke-MapDomainTrust -PageSize $PageSize | ForEach-Object { $_.SourceDomain } | Sort-Object -Unique
        }

        ForEach($DomainTrust in $DomainTrusts) {
            # get the trust groups for each domain in the trust mesh
            Write-Verbose "Enumerating trust groups in domain $DomainTrust"
            Get-ForeignUser -Domain $DomainTrust -UserName $UserName -PageSize $PageSize
        }
    }
    else {
        Get-ForeignUser -Domain $Domain -DomainController $DomainController -UserName $UserName -PageSize $PageSize
    }
}