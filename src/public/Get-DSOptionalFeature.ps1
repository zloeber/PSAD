function Get-DSOptionalFeature {
    <#
    .SYNOPSIS
    Retreives the optional directory features that are configured (such as the recycle bin)
    .DESCRIPTION
    Retreives the optional directory features that are configured (such as the recycle bin)
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .EXAMPLE
    PS> Get-DSOptionalFeatures

    Returns the optional features setup for this forest (such as the recycle bin)
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
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
        $ConfigPathContext = "CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $ConfigPathContext @DSParams)) {
            Get-DSObject -SearchRoot $ConfigPathContext @DSParams -Filter 'objectClass=msDS-OptionalFeature' -Properties *
        }
        else {
            Write-Warning "$($FunctionName): Unable to find the path - $ConfigPathContext"
        }
    }
}
