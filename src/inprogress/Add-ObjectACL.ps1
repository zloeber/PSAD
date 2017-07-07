function Add-ObjectAcl {
<#
.SYNOPSIS
Adds an ACL for a specific active directory object.

.DESCRIPTION
Adds an ACL for a specific active directory object.

.PARAMETER TargetSamAccountName
Target object name to filter for.        

.PARAMETER TargetName
Target object name to filter for.

.PARAMETER TargetDistinguishedName
Target object distinguished name to filter for.

.PARAMETER TargetFilter
A customized ldap filter string to use to find a target, e.g. "(description=*admin*)"

.PARAMETER TargetADSpath
The LDAP source for the target, e.g. "LDAP://OU=secret,DC=testlab,DC=local"

.PARAMETER TargetADSprefix
Prefix to set for the target searcher (like "CN=Sites,CN=Configuration")

.PARAMETER PrincipalSID
The SID of the principal object to add for access.

.PARAMETER PrincipalName
The name of the principal object to add for access.

.PARAMETER PrincipalSamAccountName
The samAccountName of the principal object to add for access.

.PARAMETER Rights
Rights to add for the principal, "All","ResetPassword","WriteMembers","DCSync"

.PARAMETER RightsGUID
Rights to add for the principal in GUID format.

.PARAMETER Domain
The domain to use for the target query, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.EXAMPLE
Add-ObjectAcl -TargetSamAccountName matt -PrincipalSamAccountName john

Grants 'john' all full access rights to the 'matt' account.

.EXAMPLE
Add-ObjectAcl -TargetSamAccountName matt -PrincipalSamAccountName john -Rights ResetPassword

Grants 'john' the right to reset the password for the 'matt' account.

.NOTES
AdminSDHolder ACL approach from Sean Metcalf (@pyrotek3)
https://adsecurity.org/?p=1906

ACE setting method adapted from https://social.technet.microsoft.com/Forums/windowsserver/en-US/df3bfd33-c070-4a9c-be98-c4da6e591a0a/forum-faq-using-powershell-to-assign-permissions-on-active-directory-objects.

'ResetPassword' doesn't need to know the user's current password
'WriteMembers' allows for the modification of group membership

.LINK
https://adsecurity.org/?p=1906

.LINK
https://social.technet.microsoft.com/Forums/windowsserver/en-US/df3bfd33-c070-4a9c-be98-c4da6e591a0a/forum-faq-using-powershell-to-assign-permissions-on-active-directory-objects?forum=winserverpowershell
#>

    [CmdletBinding()]
    Param (
        [String]
        $TargetSamAccountName,

        [String]
        $TargetName = "*",

        [Alias('DN')]
        [String]
        $TargetDistinguishedName = "*",

        [String]
        $TargetFilter,

        [String]
        $TargetADSpath,

        [String]
        $TargetADSprefix,

        [String]
        [ValidatePattern('^S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+')]
        $PrincipalSID,

        [String]
        $PrincipalName,

        [String]
        $PrincipalSamAccountName,

        [String]
        [ValidateSet("All","ResetPassword","WriteMembers","DCSync")]
        $Rights = "All",

        [String]
        $RightsGUID,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        $Searcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $TargetADSpath -ADSprefix $TargetADSprefix -PageSize $PageSize

        if($PrincipalSID) {
            $ResolvedPrincipalSID = $PrincipalSID
        }
        else {
            $Principal = Get-ADObject -Domain $Domain -DomainController $DomainController -Name $PrincipalName -SamAccountName $PrincipalSamAccountName -PageSize $PageSize
            
            if(!$Principal) {
                throw "Error resolving principal"
            }
            $ResolvedPrincipalSID = $Principal.objectsid
        }
        if(!$ResolvedPrincipalSID) {
            throw "Error resolving principal"
        }
    }

    process {

        if ($Searcher) {

            if($TargetSamAccountName) {
                $Searcher.filter="(&(samaccountname=$TargetSamAccountName)(name=$TargetName)(distinguishedname=$TargetDistinguishedName)$TargetFilter)"  
            }
            else {
                $Searcher.filter="(&(name=$TargetName)(distinguishedname=$TargetDistinguishedName)$TargetFilter)"  
            }
  
            try {
                $Results = $Searcher.FindAll()
                $Results | Where-Object {$_} | ForEach-Object {

                    # adapted from https://social.technet.microsoft.com/Forums/windowsserver/en-US/df3bfd33-c070-4a9c-be98-c4da6e591a0a/forum-faq-using-powershell-to-assign-permissions-on-active-directory-objects

                    $TargetDN = $_.Properties.distinguishedname

                    $Identity = [System.Security.Principal.IdentityReference] ([System.Security.Principal.SecurityIdentifier]$ResolvedPrincipalSID)
                    $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
                    $ControlType = [System.Security.AccessControl.AccessControlType] "Allow"
                    $ACEs = @()

                    if($RightsGUID) {
                        $GUIDs = @($RightsGUID)
                    }
                    else {
                        $GUIDs = Switch ($Rights) {
                            # ResetPassword doesn't need to know the user's current password
                            "ResetPassword" { "00299570-246d-11d0-a768-00aa006e0529" }
                            # allows for the modification of group membership
                            "WriteMembers" { "bf9679c0-0de6-11d0-a285-00aa003049e2" }
                            # 'DS-Replication-Get-Changes' = 1131f6aa-9c07-11d1-f79f-00c04fc2dcd2
                            # 'DS-Replication-Get-Changes-All' = 1131f6ad-9c07-11d1-f79f-00c04fc2dcd2
                            # 'DS-Replication-Get-Changes-In-Filtered-Set' = 89e95b76-444d-4c62-991a-0facbeda640c
                            #   when applied to a domain's ACL, allows for the use of DCSync
                            "DCSync" { "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2", "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2", "89e95b76-444d-4c62-991a-0facbeda640c"}
                        }
                    }

                    if($GUIDs) {
                        foreach($GUID in $GUIDs) {
                            $NewGUID = New-Object Guid $GUID
                            $ADRights = [System.DirectoryServices.ActiveDirectoryRights] "ExtendedRight"
                            $ACEs += New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$ControlType,$NewGUID,$InheritanceType
                        }
                    }
                    else {
                        # deault to GenericAll rights
                        $ADRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
                        $ACEs += New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$ControlType,$InheritanceType
                    }

                    Write-Verbose "Granting principal $ResolvedPrincipalSID '$Rights' on $($_.Properties.distinguishedname)"

                    try {
                        # add all the new ACEs to the specified object
                        ForEach ($ACE in $ACEs) {
                            Write-Verbose "Granting principal $ResolvedPrincipalSID '$($ACE.ObjectType)' rights on $($_.Properties.distinguishedname)"
                            $Object = [adsi]($_.path)
                            $Object.PsBase.ObjectSecurity.AddAccessRule($ACE)
                            $Object.PsBase.commitchanges()
                        }
                    }
                    catch {
                        Write-Warning "Error granting principal $ResolvedPrincipalSID '$Rights' on $TargetDN : $_"
                    }
                }
                $Results.dispose()
                $Searcher.dispose()
            }
            catch {
                Write-Warning "Error: $_"
            }
        }
    }
}