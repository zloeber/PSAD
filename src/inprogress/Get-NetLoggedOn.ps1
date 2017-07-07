function Get-NetLoggedon {
<#
.SYNOPSIS
This function will execute the NetWkstaUserEnum Win32API call to query
a given host for actively logged on users.

.DESCRIPTION
This function will execute the NetWkstaUserEnum Win32API call to query
a given host for actively logged on users.

.PARAMETER ComputerName

The hostname to query for logged on users.

.OUTPUTS

WKSTA_USER_INFO_1 structure. A representation of the WKSTA_USER_INFO_1
result structure which includes the username and domain of logged on users,
with the ComputerName added.

.EXAMPLE

PS C:\> Get-NetLoggedon

Returns users actively logged onto the local host.

.EXAMPLE

PS C:\> Get-NetLoggedon -ComputerName sqlserver

Returns users actively logged onto the 'sqlserver' host.

.EXAMPLE

PS C:\> Get-NetComputer | Get-NetLoggedon

Returns all logged on userse for all computers in the domain.

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

    # Declare the reference variables
    $QueryLevel = 1
    $PtrInfo = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalRead = 0
    $ResumeHandle = 0

    # get logged on user information
    $Result = $Netapi32::NetWkstaUserEnum($Computer, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

    # Locate the offset of the initial intPtr
    $Offset = $PtrInfo.ToInt64()

    # 0 = success
    if (($Result -eq 0) -and ($Offset -gt 0)) {

        # Work out how much to increment the pointer by finding out the size of the structure
        $Increment = $WKSTA_USER_INFO_1::GetSize()

        # parse all the result structures
        for ($i = 0; ($i -lt $EntriesRead); $i++) {
            # create a new int ptr at the given offset and cast the pointer as our result structure
            $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
            $Info = $NewIntPtr -as $WKSTA_USER_INFO_1

            # return all the sections of the structure
            $LoggedOn = $Info | Select-Object *
            $LoggedOn | Add-Member Noteproperty 'ComputerName' $Computer
            $Offset = $NewIntPtr.ToInt64()
            $Offset += $Increment
            $LoggedOn
        }

        # free up the result buffer
        $Null = $Netapi32::NetApiBufferFree($PtrInfo)
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
    }
}