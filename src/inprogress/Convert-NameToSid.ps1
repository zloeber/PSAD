function Convert-NameToSid {
<#
.SYNOPSIS
Converts a given user/group name to a security identifier (SID) or vice versa.

.DESCRIPTION
Converts a given user/group name to a security identifier (SID) or vice versa.

.PARAMETER ObjectName
The user/group name to convert, can be 'user' or 'DOMAIN\user' format.

.PARAMETER Domain
Specific domain for the given user account, defaults to the current domain.

.EXAMPLE
PS C:\> Convert-NameToSid 'DEV\dfm'
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [Alias('Name')]
        [String]$ObjectName,

        [Parameter()]
        [String]$Domain
    )

    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    
    $ObjectName = $ObjectName -Replace "/","\"
    
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
        $SID = $Obj.Translate([System.Security.Principal.SecurityIdentifier]).Value
        
        New-Object PSObject -Property @{
            ObjectName = $ObjectName
            SID = $SID
        }
    }
    catch {
        Write-Warning "$($FunctionName): Invalid object/name - $Domain\$ObjectName"
    }
}