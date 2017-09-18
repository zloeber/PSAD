function Get-DSSID {
<#
.SYNOPSIS
Converts a given user/group name to a security identifier (SID).
.DESCRIPTION
Converts a given user/group name to a security identifier (SID).
.PARAMETER Name
The user/group name to convert, can be 'user' or 'DOMAIN\user' format.
.PARAMETER SID
Specific domain for the given user account, defaults to the current domain.
.PARAMETER Domain
Specific domain for the given user account, defaults to the current domain.
.PARAMETER ComputerName
Fully Qualified Name of a remote domain controller to connect to.
.PARAMETER Credential
Alternate credentials for retrieving information.

.EXAMPLE
Get-DSSID -Name jdoe
#>
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param(
        [Parameter(Position = 0, Mandatory=$True, ValueFromPipeline=$True, ParameterSetName='Object')]
        [Alias('Group','User', 'Identity')]
        [String]$Name,

        [Parameter(Position = 0, Mandatory=$True, ValueFromPipeline=$True, ParameterSetName='SID')]
        [ValidatePattern('^S-1-.*')]
        [String]$SID,

        [Parameter(Position = 1)]
        [string]$Domain = ($Script:CurrentDomain).Name,

        [Parameter(Position = 2)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 3)]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    switch ($PsCmdlet.ParameterSetName) {
        'Object'  {
            $ObjectName = $Name -Replace "/","\"

            if($ObjectName.Contains("\")) {
                # if we get a DOMAIN\user format, auto convert it
                $Domain = $ObjectName.Split("\")[0]
                $ObjectName = $ObjectName.Split("\")[1]
            }
            elseif(-not $Domain) {
                Write-Verbose "$($FunctionName): No domain found in object name or passed to function, attempting to use currently connected domain name."
                try {
                    $Domain = (Get-DSCurrentConnectedDomain).Name
                }
                catch {
                    throw "$($FunctionName): Unable to retreive or find a domain name for object!"
                }
            }

            try {
                $Obj = (New-Object System.Security.Principal.NTAccount($Domain, $ObjectName))
                $Obj.Translate([System.Security.Principal.SecurityIdentifier]).Value
            }
            catch {
                Write-Warning "$($FunctionName): Invalid object/name - $Domain\$ObjectName"
            }
        }
        'SID' {
            ConvertTo-SecurityIdentifier -SID $SID
        }
    }

}