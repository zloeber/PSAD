function Find-GPOLocation {
<#
.SYNOPSIS
Enumerates the machines where a specific user/group is a member of a specific
local group, all through GPO correlation. 

.DESCRIPTION
Takes a user/group name and optional domain, and determines the computers in the domain 
the user/group has local admin (or RDP) rights to.

It does this by:
    1.  resolving the user/group to its proper SID
    2.  enumerating all groups the user/group is a current part of 
        and extracting all target SIDs to build a target SID list
    3.  pulling all GPOs that set 'Restricted Groups' or Groups.xml by calling
        Get-NetGPOGroup
    4.  matching the target SID list to the queried GPO SID list
        to enumerate all GPO the user is effectively applied with
    5.  enumerating all OUs and sites and applicable GPO GUIs are
        applied to through gplink enumerating
    6.  querying for all computers under the given OUs or sites

If no user/group is specified, all user/group -> machine mappings discovered through
GPO relationships are returned.

.PARAMETER UserName
A (single) user name name to query for access.

.PARAMETER GroupName
A (single) group name name to query for access. 

.PARAMETER Domain
Optional domain the user exists in for querying, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER LocalGroup
The local group to check access against.
Can be "Administrators" (S-1-5-32-544), "RDP/Remote Desktop Users" (S-1-5-32-555),
or a custom local SID. Defaults to local 'Administrators'.

.PARAMETER UsePSDrive
Switch. Mount any found policy files with temporary PSDrives.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.EXAMPLE
PS C:\> Find-GPOLocation

Find all user/group -> machine relationships where the user/group is a member
of the local administrators group on target machines.

.EXAMPLE
PS C:\> Find-GPOLocation -UserName dfm

Find all computers that dfm user has local administrator rights to in 
the current domain.

.EXAMPLE
PS C:\> Find-GPOLocation -UserName dfm -Domain dev.testlab.local

Find all computers that dfm user has local administrator rights to in 
the dev.testlab.local domain.

.EXAMPLE
PS C:\> Find-GPOLocation -UserName jason -LocalGroup RDP

Find all computers that jason has local RDP access rights to in the domain.

.NOTES
Author: @harmj0y
License: BSD 3-Clause
Required Dependencies: Get-NetUser, Get-NetGroup, Get-NetGPOGroup, Get-NetOU, Get-NetComputer, Get-ADObject, Get-NetSite
Optional Dependencies: None

#>

    [CmdletBinding()]
    Param (
        [String]
        $UserName,

        [String]
        $GroupName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $LocalGroup = 'Administrators',
        
        [Switch]
        $UsePSDrive,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    if($UserName) {
        # if a group name is specified, get that user object so we can extract the target SID
        $User = Get-NetUser -UserName $UserName -Domain $Domain -DomainController $DomainController -PageSize $PageSize | Select-Object -First 1
        $UserSid = $User.objectsid

        if(-not $UserSid) {    
            Throw "User '$UserName' not found!"
        }

        $TargetSIDs = @($UserSid)
        $ObjectSamAccountName = $User.samaccountname
        $TargetObject = $UserSid
    }
    elseif($GroupName) {
        # if a group name is specified, get that group object so we can extract the target SID
        $Group = Get-NetGroup -GroupName $GroupName -Domain $Domain -DomainController $DomainController -FullData -PageSize $PageSize | Select-Object -First 1
        $GroupSid = $Group.objectsid

        if(-not $GroupSid) {    
            Throw "Group '$GroupName' not found!"
        }

        $TargetSIDs = @($GroupSid)
        $ObjectSamAccountName = $Group.samaccountname
        $TargetObject = $GroupSid
    }
    else {
        $TargetSIDs = @('*')
    }

    # figure out what the SID is of the target local group we're checking for membership in
    if($LocalGroup -like "*Admin*") {
        $TargetLocalSID = 'S-1-5-32-544'
    }
    elseif ( ($LocalGroup -like "*RDP*") -or ($LocalGroup -like "*Remote*") ) {
        $TargetLocalSID = 'S-1-5-32-555'
    }
    elseif ($LocalGroup -like "S-1-5-*") {
        $TargetLocalSID = $LocalGroup
    }
    else {
        throw "LocalGroup must be 'Administrators', 'RDP', or a 'S-1-5-X' SID format."
    }

    # if we're not listing all relationships, use the tokenGroups approach from Get-NetGroup to 
    # get all effective security SIDs this object is a part of
    if($TargetSIDs[0] -and ($TargetSIDs[0] -ne '*')) {
        $TargetSIDs += Get-NetGroup -Domain $Domain -DomainController $DomainController -PageSize $PageSize -UserName $ObjectSamAccountName -RawSids
    }

    if(-not $TargetSIDs) {
        throw "No effective target SIDs!"
    }

    Write-Verbose "TargetLocalSID: $TargetLocalSID"
    Write-Verbose "Effective target SIDs: $TargetSIDs"

    $GPOGroupArgs =  @{
        'Domain' = $Domain
        'DomainController' = $DomainController
        'UsePSDrive' = $UsePSDrive
        'ResolveMemberSIDs' = $True
        'PageSize' = $PageSize
    }

    # enumerate all GPO group mappings for the target domain that involve our target SID set
    $GPOgroups = Get-NetGPOGroup @GPOGroupArgs | ForEach-Object {

        $GPOgroup = $_

        # if the locally set group is what we're looking for, check the GroupMembers ('members')
        #    for our target SID
        if($GPOgroup.GroupSID -match $TargetLocalSID) {
            $GPOgroup.GroupMembers | Where-Object {$_} | ForEach-Object {
                if ( ($TargetSIDs[0] -eq '*') -or ($TargetSIDs -Contains $_) ) {
                    $GPOgroup
                }
            }
        }
        # if the group is a 'memberof' the group we're looking for, check GroupSID against the targt SIDs 
        if( ($GPOgroup.GroupMemberOf -contains $TargetLocalSID) ) {
            if( ($TargetSIDs[0] -eq '*') -or ($TargetSIDs -Contains $GPOgroup.GroupSID) ) {
                $GPOgroup
            }
        }
    } | Sort-Object -Property GPOName -Unique

    $GPOgroups | ForEach-Object {

        $GPOname = $_.GPODisplayName
        $GPOguid = $_.GPOName
        $GPOPath = $_.GPOPath
        $GPOType = $_.GPOType
        if($_.GroupMembers) {
            $GPOMembers = $_.GroupMembers
        }
        else {
            $GPOMembers = $_.GroupSID
        }
        
        $Filters = $_.Filters

        if(-not $TargetObject) {
            # if the * wildcard was used, set the ObjectDistName as the GPO member SID set
            #   so all relationship mappings are output
            $TargetObjectSIDs = $GPOMembers
        }
        else {
            $TargetObjectSIDs = $TargetObject
        }

        # find any OUs that have this GUID applied and then retrieve any computers from the OU
        Get-NetOU -Domain $Domain -DomainController $DomainController -GUID $GPOguid -FullData -PageSize $PageSize | ForEach-Object {
            if($Filters) {
                # filter for computer name/org unit if a filter is specified
                #   TODO: handle other filters (i.e. OU filters?) again, I hate you GPP...
                $OUComputers = Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_.ADSpath -FullData -PageSize $PageSize | Where-Object {
                    $_.adspath -match ($Filters.Value)
                } | ForEach-Object { $_.dnshostname }
            }
            else {
                $OUComputers = Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_.ADSpath -PageSize $PageSize
            }

            if($OUComputers) {
                if($OUComputers -isnot [System.Array]) {$OUComputers = @($OUComputers)}

                ForEach ($TargetSid in $TargetObjectSIDs) {
                    $Object = Get-ADObject -SID $TargetSid -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize

                    $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                    $GPOLocation = New-Object PSObject
                    $GPOLocation | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                    $GPOLocation | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                    $GPOLocation | Add-Member Noteproperty 'ObjectSID' $Object.objectsid
                    $GPOLocation | Add-Member Noteproperty 'Domain' $Domain
                    $GPOLocation | Add-Member Noteproperty 'IsGroup' $IsGroup
                    $GPOLocation | Add-Member Noteproperty 'GPODisplayName' $GPOname
                    $GPOLocation | Add-Member Noteproperty 'GPOGuid' $GPOGuid
                    $GPOLocation | Add-Member Noteproperty 'GPOPath' $GPOPath
                    $GPOLocation | Add-Member Noteproperty 'GPOType' $GPOType
                    $GPOLocation | Add-Member Noteproperty 'ContainerName' $_.distinguishedname
                    $GPOLocation | Add-Member Noteproperty 'ComputerName' $OUComputers
                    $GPOLocation.PSObject.TypeNames.Add('PowerView.GPOLocalGroup')
                    $GPOLocation
                }
            }
        }

        # find any sites that have this GUID applied
        Get-NetSite -Domain $Domain -DomainController $DomainController -GUID $GPOguid -PageSize $PageSize -FullData | ForEach-Object {

            ForEach ($TargetSid in $TargetObjectSIDs) {
                $Object = Get-ADObject -SID $TargetSid -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize

                $IsGroup = @('268435456','268435457','536870912','536870913') -contains $Object.samaccounttype

                $AppliedSite = New-Object PSObject
                $AppliedSite | Add-Member Noteproperty 'ObjectName' $Object.samaccountname
                $AppliedSite | Add-Member Noteproperty 'ObjectDN' $Object.distinguishedname
                $AppliedSite | Add-Member Noteproperty 'ObjectSID' $Object.objectsid
                $AppliedSite | Add-Member Noteproperty 'IsGroup' $IsGroup
                $AppliedSite | Add-Member Noteproperty 'Domain' $Domain
                $AppliedSite | Add-Member Noteproperty 'GPODisplayName' $GPOname
                $AppliedSite | Add-Member Noteproperty 'GPOGuid' $GPOGuid
                $AppliedSite | Add-Member Noteproperty 'GPOPath' $GPOPath
                $AppliedSite | Add-Member Noteproperty 'GPOType' $GPOType
                $AppliedSite | Add-Member Noteproperty 'ContainerName' $_.distinguishedname
                $AppliedSite | Add-Member Noteproperty 'ComputerName' $_.siteobjectbl
                $AppliedSite.PSObject.TypeNames.Add('PowerView.GPOLocalGroup')
                $AppliedSite
            }
        }
    }
}