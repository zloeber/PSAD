function Get-CachedRDPConnection {
<#
.SYNOPSIS
Uses remote registry functionality to query all entries for the
"Windows Remote Desktop Connection Client" on a machine, separated by
user and target server.

.DESCRIPTION
Uses remote registry functionality to query all entries for the
"Windows Remote Desktop Connection Client" on a machine, separated by
user and target server.

Note: This function requires administrative rights on the
machine you're enumerating.

.PARAMETER ComputerName
The hostname to query for RDP client information.
Defaults to localhost.

.PARAMETER Credential
A [Management.Automation.PSCredential] object for the remote connection.

.EXAMPLE
PS C:\> Get-CachedRDPConnection

Returns the RDP connection client information for the local machine.

.EXAMPLE
PS C:\> Get-CachedRDPConnection -ComputerName WINDOWS2.testlab.local

Returns the RDP connection client information for the WINDOWS2.testlab.local machine

.EXAMPLE
PS C:\> Get-CachedRDPConnection -ComputerName WINDOWS2.testlab.local -Credential $Cred

Returns the RDP connection client information for the WINDOWS2.testlab.local machine using alternate credentials.

.EXAMPLE
PS C:\> Get-NetComputer | Get-CachedRDPConnection

Get cached RDP information for all machines in the domain.
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

                # pull out all the cached RDP connections
                $ConnectionKeys = $Reg.EnumValues($HKU,"$UserSID\Software\Microsoft\Terminal Server Client\Default").sNames

                foreach ($Connection in $ConnectionKeys) {
                    # make sure this key is a cached connection
                    if($Connection -match 'MRU.*') {
                        $TargetServer = $Reg.GetStringValue($HKU, "$UserSID\Software\Microsoft\Terminal Server Client\Default", $Connection).sValue
                        
                        $FoundConnection = New-Object PSObject
                        $FoundConnection | Add-Member Noteproperty 'ComputerName' $Computer
                        $FoundConnection | Add-Member Noteproperty 'UserName' $UserName
                        $FoundConnection | Add-Member Noteproperty 'UserSID' $UserSID
                        $FoundConnection | Add-Member Noteproperty 'TargetServer' $TargetServer
                        $FoundConnection | Add-Member Noteproperty 'UsernameHint' $Null
                        $FoundConnection
                    }
                }

                # pull out all the cached server info with username hints
                $ServerKeys = $Reg.EnumKey($HKU,"$UserSID\Software\Microsoft\Terminal Server Client\Servers").sNames

                foreach ($Server in $ServerKeys) {

                    $UsernameHint = $Reg.GetStringValue($HKU, "$UserSID\Software\Microsoft\Terminal Server Client\Servers\$Server", 'UsernameHint').sValue
                    
                    $FoundConnection = New-Object PSObject
                    $FoundConnection | Add-Member Noteproperty 'ComputerName' $Computer
                    $FoundConnection | Add-Member Noteproperty 'UserName' $UserName
                    $FoundConnection | Add-Member Noteproperty 'UserSID' $UserSID
                    $FoundConnection | Add-Member Noteproperty 'TargetServer' $Server
                    $FoundConnection | Add-Member Noteproperty 'UsernameHint' $UsernameHint
                    $FoundConnection   
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