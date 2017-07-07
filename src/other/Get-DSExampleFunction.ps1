function Get-DSExample {
<#
.SYNOPSIS
    
.DESCRIPTION
    
.PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
.PARAMETER Credential
    Alternate credentials for retrieving forest information.
.PARAMETER Identity
    Identity to search for
.EXAMPLE
    TBD
.LINK
    NA
.NOTES
    TBD
#>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    Process {
        switch ( $ADConnectState ) {
            'AltUserAndServer' {
                Write-Verbose "$($FunctionName): Alternate user and server."
                # Action
            }
            'AltUser' {
                Write-Verbose "$($FunctionName): Alternate user."
                # Action
            }
            'CurrentUserAltServer' {
                Write-Verbose "$($FunctionName): Current user, alternate server."
                # Action
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                # Action
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }
    }
}