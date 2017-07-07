function Get-DSADSchemaVersion {
    <#
    .SYNOPSIS
    Retreives the active directory schema version in human readable format.
    .DESCRIPTION
    Retreives the active directory schema version in human readable format.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .EXAMPLE
    PS> Get-DSADSchemaVersion
    .NOTES
    TBD
    .LINK
    TBD
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
    }

    process {
        $SchemaContext = (Get-DSSchema -ComputerName $ComputerName -Credential $Credential).name

        $objectVersion = (Get-DSObject -SearchScope:Base -SearchRoot $SchemaContext -Properties 'objectversion' -ComputerName $ComputerName -Credential $Credential).objectversion

        if (($Script:SchemaVersionTable).Keys -contains $objectVersion) {
            Write-Verbose "$($FunctionName): Exchange schema version found."
            $Script:SchemaVersionTable[$objectVersion]
        }
        else {
            Write-Verbose "$($FunctionName): Exchange schema version not in our list."
            $objectVersion
        }
    }
}
