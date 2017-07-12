function Split-Credential {
    <#
    .SYNOPSIS
    Enumerates the username, password, and domain of a credential object.

    .DESCRIPTION
    Enumerates the username, password, and domain of a credential object.

    .PARAMETER Credential
    The credential to enumerate.

    .EXAMPLE
    PS C:\> Get-Credential $null
    Returns the current user settings. Password will be returned as $null.

    .NOTES
    Author: Zachary Loeber

    .LINK
    https://www.the-little-things.net
    #>
    [CmdletBinding()]
    param (
        [parameter()]
        [alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential
    )
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $SplitCreds = @{
        UserName = $null
        Password = $null
        Domain = $null
        AltUser = $true
    }


    if ($Credential -eq $null) {
        if ((Get-DomainJoinStatus) -eq 'Domain') {
            Write-Verbose "$($FunctionName): No credential passed trying to use the local user instead"
            $SplitCreds.Domain,$SplitCreds.UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -split "\\"
            $SplitCreds.AltUser = $false
        }
        else {
            throw "$($FunctionName): No credentials passed and this system is not domain joined."
        }
    }
    else {
        Write-Verbose "$($FunctionName): Credential passed, splitting it up to its component parts."
        $SplitCreds.UserName= $Credential.GetNetworkCredential().UserName.ToString()
        $SplitCreds.Password = $Credential.GetNetworkCredential().Password.ToString()
        $SplitCreds.Domain = $Credential.GetNetworkCredential().Domain.ToString()
    }
    if ($SplitCreds.Domain -eq '') {
        Write-Verbose "$($FunctionName): Credential passed without a domain, looking for a forest name instead (@forest.com).."
        $SplitCreds.UserName,$SplitCreds.Domain = $SplitCreds.UserName -split "\@"
        if ($SplitCreds.Domain -eq $null) {
            Write-Verbose "$($FunctionName): Credential passed without a domain or forest name. Attempting to use current user's domain instead"
            $SplitCreds.Domain,$null = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -split "\\"
            if ($SplitCreds.Domain -eq '') {
                Write-Verbose "$($FunctionName): Credential passed without a domain or forest name."
                $SplitCreds.Domain = $null
            }
        }
    }

    $SplitCreds
}
