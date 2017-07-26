function Get-DSSCCMServiceLocatorPoint {
    <#
    .SYNOPSIS
        Retreives the SCCM service locator point AD information
    .DESCRIPTION
        Retreives the SCCM service locator point AD information
    .PARAMETER ComputerName
        Domain controller to use for this search.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .EXAMPLE
        PS> Get-DSSCCMServiceLocatorPoint

        Returns the SCCM SLPs found in the current forest
    .NOTES
        Returns SLPs as defined in AD, they may not be 'live' though.
    .LINK
        https://github.com/zloeber/psad
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $SysManageContext = "CN=System Management,CN=System,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $SysManageContext @DSParams)) {

            Get-DSObject -SearchRoot $SysManageContext @DSParams -Filter 'objectClass=mSSMSServerLocatorPoint' -Properties name,mSSMSMPName,mSSMSSiteCode,whenCreated
        }
    }
}
