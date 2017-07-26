function Get-DSForestTrust {
    <#
    .SYNOPSIS
    Retrieve an ADSI forest object.
    .DESCRIPTION
    Retrieve an ADSI forest object.
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving forest information.
    .PARAMETER Identity
    Forest name to retreive.
    .EXAMPLE
    PS> Get-DSForestTrust
    Gets the forest trusts for the domain the host is corrently joined to or that was previously connected to via Connect-DSAD.
    .OUTPUTS
    System.DirectoryServices.ActiveDirectory.ForestTrust
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name','Forest','ForestName')]
        [string]$Identity = ($Script:CurrentForest).name,

        [Parameter(Position=1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position=2)]
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
    }

    Process {
        Write-Verbose "$($FunctionName): Attempting to get forest trusts for $Identity."
        (Get-DSForest -Identity $Identity -ComputerName $ComputerName -Credential $Credential).GetAllTrustRelationships()
    }
}
