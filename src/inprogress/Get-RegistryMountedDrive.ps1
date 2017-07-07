function Get-RegistryMountedDrive {
<#
.SYNOPSIS
Uses remote registry functionality to query all entries for the
the saved network mounted drive on a machine, separated by
user and target server.

.DESCRIPTION
Uses remote registry functionality to query all entries for the
the saved network mounted drive on a machine, separated by
user and target server.

.PARAMETER ComputerName

The hostname to query for RDP client information.
Defaults to localhost.

.PARAMETER Credential

A [Management.Automation.PSCredential] object for the remote connection.

.EXAMPLE

PS C:\> Get-RegistryMountedDrive

Returns the saved network mounted drives for the local machine.

.EXAMPLE

PS C:\> Get-RegistryMountedDrive -ComputerName WINDOWS2.testlab.local

Returns the saved network mounted drives for the WINDOWS2.testlab.local machine

.EXAMPLE

PS C:\> Get-RegistryMountedDrive -ComputerName WINDOWS2.testlab.local -Credential $Cred

Returns the saved network mounted drives for the WINDOWS2.testlab.local machine using alternate credentials.

.EXAMPLE

PS C:\> Get-NetComputer | Get-RegistryMountedDrive

Get the saved network mounted drives for all machines in the domain.

.NOTES
Note: This function requires administrative rights on the
machine you're enumerating.

#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = 'localhost',

        [Management.Automation.PSCredential]
        $Credential
    )

    # extract the computer name from whatever object was passed on the pipeline
    $Computer = $ComputerName | Get-NameField

    # HKEY_USERS
    $HKU = 2147483651

    try {
        if($Credential) {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -Credential $Credential -ErrorAction SilentlyContinue
        }
        else {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -ErrorAction SilentlyContinue
        }

        # extract out the SIDs of domain users in this hive
        $UserSIDs = ($Reg.EnumKey($HKU, "")).sNames | ? { $_ -match 'S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+$' }

        foreach ($UserSID in $UserSIDs) {

            try {
                $UserName = Convert-SidToName $UserSID

                $DriveLetters = ($Reg.EnumKey($HKU, "$UserSID\Network")).sNames

                ForEach($DriveLetter in $DriveLetters) {
                    $ProviderName = $Reg.GetStringValue($HKU, "$UserSID\Network\$DriveLetter", 'ProviderName').sValue
                    $RemotePath = $Reg.GetStringValue($HKU, "$UserSID\Network\$DriveLetter", 'RemotePath').sValue
                    $DriveUserName = $Reg.GetStringValue($HKU, "$UserSID\Network\$DriveLetter", 'UserName').sValue
                    if(-not $UserName) { $UserName = '' }

                    if($RemotePath -and ($RemotePath -ne '')) {
                        $MountedDrive = New-Object PSObject
                        $MountedDrive | Add-Member Noteproperty 'ComputerName' $Computer
                        $MountedDrive | Add-Member Noteproperty 'UserName' $UserName
                        $MountedDrive | Add-Member Noteproperty 'UserSID' $UserSID
                        $MountedDrive | Add-Member Noteproperty 'DriveLetter' $DriveLetter
                        $MountedDrive | Add-Member Noteproperty 'ProviderName' $ProviderName
                        $MountedDrive | Add-Member Noteproperty 'RemotePath' $RemotePath
                        $MountedDrive | Add-Member Noteproperty 'DriveUserName' $DriveUserName
                        $MountedDrive
                    }
                }
            }
            catch {
                Write-Verbose "Error: $_"
            }
        }
    }
    catch {
        Write-Warning "Error accessing $Computer, likely insufficient permissions or firewall rules on host: $_"
    }
}