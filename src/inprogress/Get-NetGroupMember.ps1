function Get-NetGroupMember {
<#
.SYNOPSIS
This function users [ADSI] and LDAP to query the current AD context
or trusted domain for users in a specified group. If no GroupName is
specified, it defaults to querying the "Domain Admins" group.
This is a replacement for "net group 'name' /domain"

.DESCRIPTION
This function users [ADSI] and LDAP to query the current AD context
or trusted domain for users in a specified group. If no GroupName is
specified, it defaults to querying the "Domain Admins" group.
This is a replacement for "net group 'name' /domain"

.PARAMETER GroupName

The group name to query for users.

.PARAMETER SID

The Group SID to query for users. If not given, it defaults to 512 "Domain Admins"

.PARAMETER Filter

A customized ldap filter string to use, e.g. "(description=*admin*)"

.PARAMETER Domain

The domain to query for group users, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER ADSpath

The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER FullData

Switch. Returns full data objects instead of just group/users.

.PARAMETER Recurse

Switch. If the group member is a group, recursively try to query its members as well.

.PARAMETER UseMatchingRule

Switch. Use LDAP_MATCHING_RULE_IN_CHAIN in the LDAP search query when -Recurse is specified.
Much faster than manual recursion, but doesn't reveal cross-domain groups.

.PARAMETER PageSize

The PageSize to set for the LDAP searcher object.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

PS C:\> Get-NetGroupMember

Returns the usernames that of members of the "Domain Admins" domain group.

.EXAMPLE

PS C:\> Get-NetGroupMember -Domain testing -GroupName "Power Users"

Returns the usernames that of members of the "Power Users" group in the 'testing' domain.

.LINK

http://www.powershellmagazine.com/2013/05/23/pstip-retrieve-group-membership-of-an-active-directory-group-recursively/
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GroupName,

        [String]
        $SID,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $FullData,

        [Switch]
        $Recurse,

        [Switch]
        $UseMatchingRule,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        if($DomainController) {
            $TargetDomainController = $DomainController
        }
        else {
            $TargetDomainController = ((Get-NetDomain -Credential $Credential).PdcRoleOwner).Name
        }

        if($Domain) {
            $TargetDomain = $Domain
        }
        else {
            $TargetDomain = Get-NetDomain -Credential $Credential | Select-Object -ExpandProperty name
        }

        # so this isn't repeated if users are passed on the pipeline
        $GroupSearcher = Get-DomainSearcher -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }

    process {
        if ($GroupSearcher) {
            if ($Recurse -and $UseMatchingRule) {
                # resolve the group to a distinguishedname
                if ($GroupName) {
                    $Group = Get-NetGroup -AllTypes -GroupName $GroupName -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -FullData -PageSize $PageSize
                }
                elseif ($SID) {
                    $Group = Get-NetGroup -AllTypes -SID $SID -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -FullData -PageSize $PageSize
                }
                else {
                    # default to domain admins
                    $SID = (Get-DomainSID -Domain $TargetDomain -DomainController $TargetDomainController) + "-512"
                    $Group = Get-NetGroup -AllTypes -SID $SID -Domain $TargetDomain -DomainController $TargetDomainController -Credential $Credential -FullData -PageSize $PageSize
                }
                $GroupDN = $Group.distinguishedname
                $GroupFoundName = $Group.samaccountname

                if ($GroupDN) {
                    $GroupSearcher.filter = "(&(samAccountType=805306368)(memberof:1.2.840.113556.1.4.1941:=$GroupDN)$Filter)"
                    $GroupSearcher.PropertiesToLoad.AddRange(('distinguishedName','samaccounttype','lastlogon','lastlogontimestamp','dscorepropagationdata','objectsid','whencreated','badpasswordtime','accountexpires','iscriticalsystemobject','name','usnchanged','objectcategory','description','codepage','instancetype','countrycode','distinguishedname','cn','admincount','logonhours','objectclass','logoncount','usncreated','useraccountcontrol','objectguid','primarygroupid','lastlogoff','samaccountname','badpwdcount','whenchanged','memberof','pwdlastset','adspath'))

                    $Members = $GroupSearcher.FindAll()
                    $GroupFoundName = $GroupName
                }
                else {
                    Write-Error "Unable to find Group"
                }
            }
            else {
                if ($GroupName) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(samaccountname=$GroupName)$Filter)"
                }
                elseif ($SID) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }
                else {
                    # default to domain admins
                    $SID = (Get-DomainSID -Domain $TargetDomain -DomainController $TargetDomainController) + "-512"
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }

                try {
                    $Result = $GroupSearcher.FindOne()
                }
                catch {
                    $Members = @()
                }

                $GroupFoundName = ''

                if ($Result) {
                    $Members = $Result.properties.item("member")

                    if($Members.count -eq 0) {

                        $Finished = $False
                        $Bottom = 0
                        $Top = 0

                        while(!$Finished) {
                            $Top = $Bottom + 1499
                            $MemberRange="member;range=$Bottom-$Top"
                            $Bottom += 1500
                            
                            $GroupSearcher.PropertiesToLoad.Clear()
                            [void]$GroupSearcher.PropertiesToLoad.Add("$MemberRange")
                            [void]$GroupSearcher.PropertiesToLoad.Add("samaccountname")
                            try {
                                $Result = $GroupSearcher.FindOne()
                                $RangedProperty = $Result.Properties.PropertyNames -like "member;range=*"
                                $Members += $Result.Properties.item($RangedProperty)
                                $GroupFoundName = $Result.properties.item("samaccountname")[0]

                                if ($Members.count -eq 0) { 
                                    $Finished = $True
                                }
                            }
                            catch [System.Management.Automation.MethodInvocationException] {
                                $Finished = $True
                            }
                        }
                    }
                    else {
                        $GroupFoundName = $Result.properties.item("samaccountname")[0]
                        $Members += $Result.Properties.item($RangedProperty)
                    }
                }
                $GroupSearcher.dispose()
            }

            $Members | Where-Object {$_} | ForEach-Object {
                # if we're doing the LDAP_MATCHING_RULE_IN_CHAIN recursion
                if ($Recurse -and $UseMatchingRule) {
                    $Properties = $_.Properties
                } 
                else {
                    if($TargetDomainController) {
                        $Result = [adsi]"LDAP://$TargetDomainController/$_"
                    }
                    else {
                        $Result = [adsi]"LDAP://$_"
                    }
                    if($Result){
                        $Properties = $Result.Properties
                    }
                }

                if($Properties) {

                    $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Properties.samaccounttype

                    if ($FullData) {
                        $GroupMember = Convert-LDAPProperty -Properties $Properties
                    }
                    else {
                        $GroupMember = New-Object PSObject
                    }

                    $GroupMember | Add-Member Noteproperty 'GroupDomain' $TargetDomain
                    $GroupMember | Add-Member Noteproperty 'GroupName' $GroupFoundName

                    if($Properties.objectSid) {
                        $MemberSID = ((New-Object System.Security.Principal.SecurityIdentifier $Properties.objectSid[0],0).Value)
                    }
                    else {
                        $MemberSID = $Null
                    }

                    try {
                        $MemberDN = $Properties.distinguishedname[0]

                        if (($MemberDN -match 'ForeignSecurityPrincipals') -and ($MemberDN -match 'S-1-5-21')) {
                            try {
                                if(-not $MemberSID) {
                                    $MemberSID = $Properties.cn[0]
                                }
                                $MemberSimpleName = Convert-SidToName -SID $MemberSID | Convert-ADName -InputType 'NT4' -OutputType 'Simple'
                                if($MemberSimpleName) {
                                    $MemberDomain = $MemberSimpleName.Split('@')[1]
                                }
                                else {
                                    Write-Warning "Error converting $MemberDN"
                                    $MemberDomain = $Null
                                }
                            }
                            catch {
                                Write-Warning "Error converting $MemberDN"
                                $MemberDomain = $Null
                            }
                        }
                        else {
                            # extract the FQDN from the Distinguished Name
                            $MemberDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                        }
                    }
                    catch {
                        $MemberDN = $Null
                        $MemberDomain = $Null
                    }

                    if ($Properties.samaccountname) {
                        # forest users have the samAccountName set
                        $MemberName = $Properties.samaccountname[0]
                    } 
                    else {
                        # external trust users have a SID, so convert it
                        try {
                            $MemberName = Convert-SidToName $Properties.cn[0]
                        }
                        catch {
                            # if there's a problem contacting the domain to resolve the SID
                            $MemberName = $Properties.cn
                        }
                    }

                    $GroupMember | Add-Member Noteproperty 'MemberDomain' $MemberDomain
                    $GroupMember | Add-Member Noteproperty 'MemberName' $MemberName
                    $GroupMember | Add-Member Noteproperty 'MemberSID' $MemberSID
                    $GroupMember | Add-Member Noteproperty 'IsGroup' $IsGroup
                    $GroupMember | Add-Member Noteproperty 'MemberDN' $MemberDN
                    $GroupMember.PSObject.TypeNames.Add('PowerView.GroupMember')
                    $GroupMember

                    # if we're doing manual recursion
                    if ($Recurse -and !$UseMatchingRule -and $IsGroup -and $MemberName) {
                        if($FullData) {
                            Get-NetGroupMember -FullData -Domain $MemberDomain -DomainController $TargetDomainController -Credential $Credential -GroupName $MemberName -Recurse -PageSize $PageSize
                        }
                        else {
                            Get-NetGroupMember -Domain $MemberDomain -DomainController $TargetDomainController -Credential $Credential -GroupName $MemberName -Recurse -PageSize $PageSize
                        }
                    }
                }
            }
        }
    }
}