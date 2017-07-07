function Get-LoggedOnLocal {
<#
.SYNOPSIS
This function will query the HKU registry values to retrieve the local
logged on users SID and then attempt and reverse it.
Adapted technique from Sysinternal's PSLoggedOn script. Benefit over
using the NetWkstaUserEnum API (Get-NetLoggedon) of less user privileges
required (NetWkstaUserEnum requires remote admin access).

.DESCRIPTION
This function will query the HKU registry values to retrieve the local
logged on users SID and then attempt and reverse it.
Adapted technique from Sysinternal's PSLoggedOn script. Benefit over
using the NetWkstaUserEnum API (Get-NetLoggedon) of less user privileges
required (NetWkstaUserEnum requires remote admin access).

Note: This function requires only domain user rights on the
machine you're enumerating, but remote registry must be enabled.

.PARAMETER ComputerName

The ComputerName to query for active sessions.

.EXAMPLE

PS C:\> Get-LoggedOnLocal

Returns active sessions on the local host.

.EXAMPLE

PS C:\> Get-LoggedOnLocal -ComputerName sqlserver

Returns active sessions on the 'sqlserver' host.

.NOTES
Function: Get-LoggedOnLocal
Author: Matt Kelly, @BreakersAll

#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost'
    )

    # process multiple host object types from the pipeline
    $ComputerName = Get-NameField -Object $ComputerName

    try {
        # retrieve HKU remote registry values
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', "$ComputerName")

        # sort out bogus sid's like _class
        $Reg.GetSubKeyNames() | Where-Object { $_ -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' } | ForEach-Object {
            $UserName = Convert-SidToName $_

            $Parts = $UserName.Split('\')
            $UserDomain = $Null
            $UserName = $Parts[-1]
            if ($Parts.Length -eq 2) {
                $UserDomain = $Parts[0]
            }

            $LocalLoggedOnUser = New-Object PSObject
            $LocalLoggedOnUser | Add-Member Noteproperty 'ComputerName' "$ComputerName"
            $LocalLoggedOnUser | Add-Member Noteproperty 'UserDomain' $UserDomain
            $LocalLoggedOnUser | Add-Member Noteproperty 'UserName' $UserName
            $LocalLoggedOnUser | Add-Member Noteproperty 'UserSID' $_
            $LocalLoggedOnUser
        }
    }
    catch {
        Write-Verbose "Error opening remote registry on '$ComputerName'"
    }
}