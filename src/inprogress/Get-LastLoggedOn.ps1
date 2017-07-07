function Get-LastLoggedOn {
<#
.SYNOPSIS
This function uses remote registry functionality to return
the last user logged onto a target machine.

.DESCRIPTION
This function uses remote registry functionality to return
the last user logged onto a target machine.

Note: This function requires administrative rights on the
machine you're enumerating.

.PARAMETER ComputerName

The hostname to query for the last logged on user.
Defaults to the localhost.

.PARAMETER Credential

A [Management.Automation.PSCredential] object for the remote connection.

.EXAMPLE

PS C:\> Get-LastLoggedOn

Returns the last user logged onto the local machine.

.EXAMPLE

PS C:\> Get-LastLoggedOn -ComputerName WINDOWS1

Returns the last user logged onto WINDOWS1

.EXAMPLE

PS C:\> Get-NetComputer | Get-LastLoggedOn

Returns the last user logged onto all machines in the domain.
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

    # HKEY_LOCAL_MACHINE
    $HKLM = 2147483650

    # try to open up the remote registry key to grab the last logged on user
    try {

        if($Credential) {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -Credential $Credential -ErrorAction SilentlyContinue
        }
        else {
            $Reg = Get-WmiObject -List 'StdRegProv' -Namespace root\default -Computername $Computer -ErrorAction SilentlyContinue
        }

        $Key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
        $Value = "LastLoggedOnUser"
        $LastUser = $Reg.GetStringValue($HKLM, $Key, $Value).sValue

        $LastLoggedOn = New-Object PSObject
        $LastLoggedOn | Add-Member Noteproperty 'ComputerName' $Computer
        $LastLoggedOn | Add-Member Noteproperty 'LastLoggedOn' $LastUser
        $LastLoggedOn
    }
    catch {
        Write-Warning "[!] Error opening remote registry on $Computer. Remote registry likely not enabled."
    }
}