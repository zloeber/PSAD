function Find-ManagedSecurityGroups {
<#
.SYNOPSIS
This function retrieves all security groups in the domain and identifies ones that
have a manager set. It also determines whether the manager has the ability to add
or remove members from the group.

.DESCRIPTION
Authority to manipulate the group membership of AD security groups and distribution groups 
can be delegated to non-administrators by setting the 'managedBy' attribute. This is typically
used to delegate management authority to distribution groups, but Windows supports security groups
being managed in the same way.

This function searches for AD groups which have a group manager set, and determines whether that
user can manipulate group membership. This could be a useful method of horizontal privilege
escalation, especially if the manager can manipulate the membership of a privileged group.

.EXAMPLE
PS C:\> Find-ManagedSecurityGroups | Export-PowerViewCSV -NoTypeInformation group-managers.csv

Store a list of all security groups with managers in group-managers.csv

.NOTES
Author: Stuart Morgan (@ukstufus) <stuart.morgan@mwrinfosecurity.com>
License: BSD 3-Clause

.LINK
https://github.com/PowerShellEmpire/Empire/pull/119
#>

    # Go through the list of security groups on the domain and identify those who have a manager
    Get-NetGroup -FullData -Filter '(managedBy=*)' | Select-Object -Unique distinguishedName,managedBy,cn | ForEach-Object {

        # Retrieve the object that the managedBy DN refers to
        $group_manager = Get-ADObject -ADSPath $_.managedBy | Select-Object cn,distinguishedname,name,samaccounttype,samaccountname

        # Create a results object to store our findings
        $results_object = New-Object -TypeName PSObject -Property @{
            'GroupCN' = $_.cn
            'GroupDN' = $_.distinguishedname
            'ManagerCN' = $group_manager.cn
            'ManagerDN' = $group_manager.distinguishedName
            'ManagerSAN' = $group_manager.samaccountname
            'ManagerType' = ''
            'CanManagerWrite' = $FALSE
        }

        # Determine whether the manager is a user or a group
        if ($group_manager.samaccounttype -eq 0x10000000) {
            $results_object.ManagerType = 'Group'
        } elseif ($group_manager.samaccounttype -eq 0x30000000) {
            $results_object.ManagerType = 'User'
        }

        # Find the ACLs that relate to the ability to write to the group
        $xacl = Get-ObjectAcl -ADSPath $_.distinguishedname -Rights WriteMembers

        # Double-check that the manager
        if ($xacl.ObjectType -eq 'bf9679c0-0de6-11d0-a285-00aa003049e2' -and $xacl.AccessControlType -eq 'Allow' -and $xacl.IdentityReference.Value.Contains($group_manager.samaccountname)) {
            $results_object.CanManagerWrite = $TRUE
        }
        $results_object
    }
}