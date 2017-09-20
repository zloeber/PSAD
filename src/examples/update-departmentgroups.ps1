# Takes a list of departments that are assigned to user accounts and assigns users to an associated group if they don't already
# exist as a member. If a user account is found that doesn't have the title of the department they are removed from the group.

# CSV file containing two rows, Department and DepartmentSecurityGroup
$ImportFile = 'C:\temp\DeptList.csv'
$MisplacedUserExport = 'C:\temp\MisplacedUsers.csv'

# Supply an account with permissions to update the groups
$cred = Get-Credential

import-module psad

$Departments = Import-CSV $ImportFile
$MisplacedUsers = @()
Foreach ($Department in $Departments) {
    Write-Output "Processing Department/group: $($Department.Department) - $($Department.DepartmentSecurityGroup)"
    # Add in the users to the group
    Get-DSUser -Enabled -Filter "department=$($Department.Department)" | Add-DSGroupMember -Group $Department.DepartmentSecurityGroup -Force -Credential $cred

    # Remove any users that are in the group but are not in the same department
    Get-DSGroupMember -Identity $Department.DepartmentSecurityGroup -Properties @('name','distinguishedname','sAMAccountType','department') | Where-Object {($_.sAMAccountType -eq 805306368) -and ($_.department -ne $Department.department)} | Foreach {
        Write-Output "Found an account in this group from another department: $($_.name) ($($_.department)) "
        $MisplacedUsers += New-Object -TypeName psobject -Property @{
            'group' = $Department.DepartmentSecurityGroup
            'user' = $_.name
            'userdept' = $_.department
        }
        #Remove-DSGroupMember -Identity $_.distinguishedname -Group $Department.DepartmentSecurityGroup
    }
}

$MisplacedUsers | Export-CSV -NoTypeInformation -Path $MisplacedUserExport