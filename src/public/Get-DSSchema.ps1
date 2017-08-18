function Get-DSSchema {
    <#
    .SYNOPSIS
    Get information of the schema for the existing forest.
    .DESCRIPTION
    Get information of the schema for the existing forest.
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving information.
    .PARAMETER ForestName
    Forest to retrieve.
    .PARAMETER UpdateCurrent
    Update the currently stored connected schema information within the module.
    .EXAMPLE
    C:\PS> Get-DSSchema
    Get information on the current schema for the forest currently connected to.
    .OUTPUTS
    System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('Name','Forest')]
        [string]$ForestName,

        [Parameter()]
        [switch]$UpdateCurrent
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
        try {
            $ForestContext = Get-DSDirectoryContext -ContextType 'Forest' -ContextName $ForestName -ComputerName $ComputerName -Credential $Credential
            $Schema = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]::GetSchema($ForestContext)

            if ($UpdateCurrent) {
                $Script:CurrentSchema = $Schema
            }
            else {
                $Schema
            }
        }
        catch {
            throw
        }
    }
}
