function Invoke-CheckLocalAdminAccess {
<#
.SYNOPSIS
This function will use the OpenSCManagerW Win32API call to establish
a handle to the remote host. If this succeeds, the current user context
has local administrator acess to the target.

.DESCRIPTION
This function will use the OpenSCManagerW Win32API call to establish
a handle to the remote host. If this succeeds, the current user context
has local administrator acess to the target.

.PARAMETER ComputerName

The hostname to query for active sessions.

.OUTPUTS

$True if the current user has local admin access to the hostname, $False otherwise

.EXAMPLE

PS C:\> Invoke-CheckLocalAdminAccess -ComputerName sqlserver

Returns active sessions on the local host.

.EXAMPLE

PS C:\> Get-NetComputer | Invoke-CheckLocalAdminAccess

Sees what machines in the domain the current user has access to.

.NOTES
Idea stolen from the local_admin_search_enum post module in Metasploit written by:
    'Brandon McCann "zeknox" <bmccann[at]accuvant.com>'
    'Thomas McCarthy "smilingraccoon" <smilingraccoon[at]gmail.com>'
    'Royce Davis "r3dy" <rdavis[at]accuvant.com>'

.LINK
https://github.com/rapid7/metasploit-framework/blob/master/modules/post/windows/gather/local_admin_search_enum.rb

.LINK
http://www.powershellmagazine.com/2014/09/25/easily-defining-enums-structs-and-win32-functions-in-memory/
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    # extract the computer name from whatever object was passed on the pipeline
    $Computer = $ComputerName | Get-NameField

    # 0xF003F - SC_MANAGER_ALL_ACCESS
    #   http://msdn.microsoft.com/en-us/library/windows/desktop/ms685981(v=vs.85).aspx
    $Handle = $Advapi32::OpenSCManagerW("\\$Computer", 'ServicesActive', 0xF003F);$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    Write-Verbose "Invoke-CheckLocalAdminAccess handle: $Handle"

    $IsAdmin = New-Object PSObject
    $IsAdmin | Add-Member Noteproperty 'ComputerName' $Computer

    # if we get a non-zero handle back, everything was successful
    if ($Handle -ne 0) {
        $Null = $Advapi32::CloseServiceHandle($Handle)
        $IsAdmin | Add-Member Noteproperty 'IsAdmin' $True
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        $IsAdmin | Add-Member Noteproperty 'IsAdmin' $False
    }

    $IsAdmin
}