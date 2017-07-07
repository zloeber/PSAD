function Get-NetSession {
<#
.SYNOPSIS
This function will execute the NetSessionEnum Win32API call to query a given host for active sessions on the host.

.DESCRIPTION
This function will execute the NetSessionEnum Win32API call to query a given host for active sessions on the host.

.PARAMETER ComputerName
The ComputerName to query for active sessions.

.PARAMETER UserName
The user name to filter for active sessions.

.OUTPUTS
SESSION_INFO_10 structure. A representation of the SESSION_INFO_10
result structure which includes the host and username associated
with active sessions, with the ComputerName added.

.EXAMPLE
PS C:\> Get-NetSession

Returns active sessions on the local host.

.EXAMPLE
PS C:\> Get-NetSession -ComputerName sqlserver

Returns active sessions on the 'sqlserver' host.

.EXAMPLE
PS C:\> Get-NetDomainController | Get-NetSession

Returns active sessions on all domain controllers.

.NOTES
Heavily adapted from dunedinite's post on stackoverflow (see LINK)

.LINK
http://www.powershellmagazine.com/2014/09/25/easily-defining-enums-structs-and-win32-functions-in-memory/
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [String]
        $UserName = ''
    )

    # extract the computer name from whatever object was passed on the pipeline
    $Computer = $ComputerName | Get-NameField

    # arguments for NetSessionEnum
    $QueryLevel = 10
    $PtrInfo = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalRead = 0
    $ResumeHandle = 0

    # get session information
    $Result = $Netapi32::NetSessionEnum($Computer, '', $UserName, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

    # Locate the offset of the initial intPtr
    $Offset = $PtrInfo.ToInt64()

    # 0 = success
    if (($Result -eq 0) -and ($Offset -gt 0)) {

        # Work out how much to increment the pointer by finding out the size of the structure
        $Increment = $SESSION_INFO_10::GetSize()

        # parse all the result structures
        for ($i = 0; ($i -lt $EntriesRead); $i++) {
            # create a new int ptr at the given offset and cast the pointer as our result structure
            $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
            $Info = $NewIntPtr -as $SESSION_INFO_10

            # return all the sections of the structure
            $Sessions = $Info | Select-Object *
            $Sessions | Add-Member Noteproperty 'ComputerName' $Computer
            $Offset = $NewIntPtr.ToInt64()
            $Offset += $Increment
            $Sessions
        }
        # free up the result buffer
        $Null = $Netapi32::NetApiBufferFree($PtrInfo)
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
    }
}