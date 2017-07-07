function Get-NetProcess {
<#
.SYNOPSIS
Gets a list of processes/owners on a remote machine.

.DESCRIPTION
Gets a list of processes/owners on a remote machine.

.PARAMETER ComputerName

The hostname to query processes. Defaults to the local host name.

.PARAMETER Credential

A [Management.Automation.PSCredential] object for the remote connection.

.EXAMPLE

PS C:\> Get-NetProcess -ComputerName WINDOWS1

Returns the current processes for WINDOWS1
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [Object[]]
        [ValidateNotNullOrEmpty()]
        $ComputerName = [System.Net.Dns]::GetHostName(),

        [Management.Automation.PSCredential]
        $Credential
    )

    # extract the computer name from whatever object was passed on the pipeline
    $Computer = $ComputerName | Get-NameField

    try {
        if($Credential) {
            $Processes = Get-WMIobject -Class Win32_process -ComputerName $ComputerName -Credential $Credential
        }
        else {
            $Processes = Get-WMIobject -Class Win32_process -ComputerName $ComputerName
        }

        $Processes | ForEach-Object {
            $Owner = $_.getowner();
            $Process = New-Object PSObject
            $Process | Add-Member Noteproperty 'ComputerName' $Computer
            $Process | Add-Member Noteproperty 'ProcessName' $_.ProcessName
            $Process | Add-Member Noteproperty 'ProcessID' $_.ProcessID
            $Process | Add-Member Noteproperty 'Domain' $Owner.Domain
            $Process | Add-Member Noteproperty 'User' $Owner.User
            $Process                
        }
    }
    catch {
        Write-Verbose "[!] Error enumerating remote processes on $Computer, access likely denied: $_"
    }
}
