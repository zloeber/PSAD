function Add-NetUser {
<#
.SYNOPSIS
Adds a domain user or a local user to the current (or remote) machine,
if permissions allow, utilizing the WinNT service provider and
DirectoryServices.AccountManagement, respectively.

The default behavior is to add a user to the local machine.
An optional group name to add the user to can be specified.

.DESCRIPTION
Adds a domain user or a local user to the current (or remote) machine,
if permissions allow, utilizing the WinNT service provider and
DirectoryServices.AccountManagement, respectively.

The default behavior is to add a user to the local machine.
An optional group name to add the user to can be specified.

.PARAMETER UserName
The username to add. If not given, it defaults to 'backdoor'

.PARAMETER Password
The password to set for the added user. If not given, it defaults to 'Password123!'

.PARAMETER GroupName
Group to optionally add the user to.

.PARAMETER ComputerName
Hostname to add the local user to, defaults to 'localhost'

.PARAMETER Domain
Specified domain to add the user to.

.EXAMPLE
PS C:\> Add-NetUser -UserName john -Password 'Password123!'

Adds a localuser 'john' to the local machine with password of 'Password123!'

.EXAMPLE
PS C:\> Add-NetUser -UserName john -Password 'Password123!' -ComputerName server.testlab.local

Adds a localuser 'john' with password of 'Password123!' to server.testlab.local's local Administrators group.

.EXAMPLE
PS C:\> Add-NetUser -UserName john -Password password -GroupName "Domain Admins" -Domain ''

Adds the user "john" with password "password" to the current domain and adds
the user to the domain group "Domain Admins"

.EXAMPLE
PS C:\> Add-NetUser -UserName john -Password password -GroupName "Domain Admins" -Domain 'testing'
Adds the user "john" with password "password" to the 'testing' domain and adds
the user to the domain group "Domain Admins"

.Link
http://blogs.technet.com/b/heyscriptingguy/archive/2010/11/23/use-powershell-to-create-local-user-accounts.aspx
#>

    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [String]
        $UserName = 'backdoor',

        [ValidateNotNullOrEmpty()]
        [String]
        $Password = 'Password123!',

        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateNotNullOrEmpty()]
        [Alias('HostName')]
        [String]
        $ComputerName = 'localhost',

        [ValidateNotNullOrEmpty()]
        [String]
        $Domain
    )

    if ($Domain) {

        $DomainObject = Get-NetDomain -Domain $Domain
        if(-not $DomainObject) {
            Write-Warning "Error in grabbing $Domain object"
            return $Null
        }

        # add the assembly we need
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement

        # http://richardspowershellblog.wordpress.com/2008/05/25/system-directoryservices-accountmanagement/
        # get the domain context
        $Context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList ([System.DirectoryServices.AccountManagement.ContextType]::Domain), $DomainObject

        # create the user object
        $User = New-Object -TypeName System.DirectoryServices.AccountManagement.UserPrincipal -ArgumentList $Context

        # set user properties
        $User.Name = $UserName
        $User.SamAccountName = $UserName
        $User.PasswordNotRequired = $False
        $User.SetPassword($Password)
        $User.Enabled = $True

        Write-Verbose "Creating user $UserName to with password '$Password' in domain $Domain"

        try {
            # commit the user
            $User.Save()
            "[*] User $UserName successfully created in domain $Domain"
        }
        catch {
            Write-Warning '[!] User already exists!'
            return
        }
    }
    else {
        
        Write-Verbose "Creating user $UserName to with password '$Password' on $ComputerName"

        # if it's not a domain add, it's a local machine add
        $ObjOu = [ADSI]"WinNT://$ComputerName"
        $ObjUser = $ObjOu.Create('User', $UserName)
        $ObjUser.SetPassword($Password)

        # commit the changes to the local machine
        try {
            $Null = $ObjUser.SetInfo()
            "[*] User $UserName successfully created on host $ComputerName"
        }
        catch {
            Write-Warning '[!] Account already exists!'
            return
        }
    }

    # if a group is specified, invoke Add-NetGroupUser and return its value
    if ($GroupName) {
        # if we're adding the user to a domain
        if ($Domain) {
            Add-NetGroupUser -UserName $UserName -GroupName $GroupName -Domain $Domain
            "[*] User $UserName successfully added to group $GroupName in domain $Domain"
        }
        # otherwise, we're adding to a local group
        else {
            Add-NetGroupUser -UserName $UserName -GroupName $GroupName -ComputerName $ComputerName
            "[*] User $UserName successfully added to group $GroupName on host $ComputerName"
        }
    }
}