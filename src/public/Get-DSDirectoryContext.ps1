function Get-DSDirectoryContext {
<#
.SYNOPSIS
    Get a DirectoryContext object for a specified context.
.DESCRIPTION
    Get a DirectoryContext object for a specified context.
.PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
.PARAMETER Credential
    Alternate credentials for retrieving forest information.
.PARAMETER ContextType
    Type of DirectoryContext to create. Can be ApplicationPartition ,ConfigurationSet, DirectoryServer, Domain, or Forest. Defaults to Domain.
.PARAMETER ContextName
    Can be a forest, domain, or server name (depending on the context type)
.EXAMPLE
    TBD
.OUTPUTS
    System.DirectoryService.DirectoryContext
.LINK
    NA
.NOTES
    None
#>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,
        
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [ValidateSet('ApplicationPartition','ConfigurationSet','DirectoryServer','Domain','Forest')]
        [Alias('Type','Context')]
        [string]$ContextType = 'Domain',

        [Parameter()]
        [Alias('Name','Domain','Forest','DomainName','ForestName')]
        [string]$ContextName
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    Process {
       switch ($ContextType) {
            'Domain' {
                if ([string]::IsNullOrEmpty($ContextName)) {
                    if ($Script:CurrentDomain -ne $null) {
                        $ContextName = ($Script:CurrentDomain).Name
                    }
                    else {
                        $ContextName = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                    }
                }
                $ArgumentList = $ContextType,$ContextName
            }
            'Forest' {
                if ([string]::IsNullOrEmpty($ContextName)) {
                    if ($Script:CurrentForest -ne $null) {
                        $ContextName = ($Script:CurrentForest).Name
                    }
                    else {
                        $ContextName = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentforest()
                    }
                }
                $ArgumentList = $ContextType,$ContextName
            }
            'DirectoryServer' {
                if ([string]::IsNullOrEmpty($ContextName)) {
                    if ([string]::IsNullOrEmpty($Script:CurrentServer)) {
                        throw "$($FunctionName): No currently connected server and no context name was passed, cannot create a DirectoryContext as a DirectoryServer"
                    }
                    else {
                        $ContextName = $Script:CurrentServer
                    }
                }
                $ArgumentList = $ContextType,$ContextName
            }
            Default { $ArgumentList = $ContextType }
        }
        switch ( $ADConnectState ) {
            'AltUserAndServer' {
                $ArgumentList += "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password
            }
            'AltUser' {
                $ArgumentList += "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password
            }

        }
        
        New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList $ArgumentList
    }
}
