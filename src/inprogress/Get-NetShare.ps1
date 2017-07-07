function Get-NetShare {
<#
.SYNOPSIS
This function will execute the NetShareEnum Win32API call to query a given host for open shares. This is a replacement for"net share \\hostname"

.DESCRIPTION
This function will execute the NetShareEnum Win32API call to query a given host for open shares. This is a replacement for"net share \\hostname"

.PARAMETER ComputerName
The hostname to query for shares. Also accepts IP addresses.

.OUTPUTS
SHARE_INFO_1 structure. A representation of the SHARE_INFO_1
result structure which includes the name and note for each share,
with the ComputerName added.

.EXAMPLE
PS C:\> Get-NetShare

Returns active shares on the local host.

.EXAMPLE
PS C:\> Get-NetShare -ComputerName sqlserver

Returns active shares on the 'sqlserver' host

.EXAMPLE
PS C:\> Get-NetComputer | Get-NetShare

Returns all shares for all computers in the domain.

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

    # arguments for NetShareEnum
    $QueryLevel = 1
    $PtrInfo = [IntPtr]::Zero
    $EntriesRead = 0
    $TotalRead = 0
    $ResumeHandle = 0

    # get the share information
    $Result = $Netapi32::NetShareEnum($Computer, $QueryLevel, [ref]$PtrInfo, -1, [ref]$EntriesRead, [ref]$TotalRead, [ref]$ResumeHandle)

    # Locate the offset of the initial intPtr
    $Offset = $PtrInfo.ToInt64()

    # 0 = success
    if (($Result -eq 0) -and ($Offset -gt 0)) {

        # Work out how much to increment the pointer by finding out the size of the structure
        $Increment = $SHARE_INFO_1::GetSize()

        # parse all the result structures
        for ($i = 0; ($i -lt $EntriesRead); $i++) {
            # create a new int ptr at the given offset and cast the pointer as our result structure
            $NewIntPtr = New-Object System.Intptr -ArgumentList $Offset
            $Info = $NewIntPtr -as $SHARE_INFO_1

            # return all the sections of the structure
            $Shares = $Info | Select-Object *
            $Shares | Add-Member Noteproperty 'ComputerName' $Computer
            $Offset = $NewIntPtr.ToInt64()
            $Offset += $Increment
            $Shares
        }

        # free up the result buffer
        $Null = $Netapi32::NetApiBufferFree($PtrInfo)
    }
    else {
        Write-Verbose "Error: $(([ComponentModel.Win32Exception] $Result).Message)"
    }
}