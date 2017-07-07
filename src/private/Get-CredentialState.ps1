function Get-CredentialState {
    <#
    .SYNOPSIS
    Returns the type of connection you have based on what is passed.

    .DESCRIPTION
    Returns the type of connection you have based on what is passed.

    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.

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
        [Parameter()]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $CurrCreds = Split-Credential -Credential $Credential

    if ( $CurrCreds.AltUser -and (-not [string]::IsNullOrEmpty($ComputerName))) {
        return 'AltUserAndServer'
    }
    elseif ($CurrCreds.AltUser) {
        return 'AltUser'
    }
    elseif (-not [string]::IsNullOrEmpty($ComputerName)) {
        return 'CurrentUserAltServer'
    }
    else {
        return 'CurrentUser'
    }
}
