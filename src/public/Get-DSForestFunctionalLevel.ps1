function Get-DSForestFunctionalLevel {
    <#
    .SYNOPSIS
    Retrieves the current connected forest functional level.
    .DESCRIPTION
    Retrieves the current connected forest functional level.
    .EXAMPLE
    PS> Get-DSADForestFunctionalLevel

    Retrieves the current connected forest functional level.
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter( position = 0, HelpMessage='Domain controller to use for this search.' )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( HelpMessage='Credentials to connect with.' )]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
    )

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $BaseParamSplat = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
    }
    process {
        try {
            $ForestFL = (get-dsobject @BaseParamSplat -SearchRoot "CN=Partitions,$((Get-DSConfigPartition @BaseParamSplat).distinguishedname)" -SearchScope:Base -Properties 'msds-behavior-version').'msds-behavior-version'
            if (($Script:ForestFunctionalLevel).Keys -contains $ForestFL) {
                Write-Verbose "$($FunctionName): Forest functional level version found ($ForestFL)."
                $Script:ForestFunctionalLevel[$ForestFL]
            }
            else {
                Write-Verbose "$($FunctionName): Forest functional level version not in our list."
                $ForestFL
            }

        }
        catch {
            throw $_
        }
    }
}
