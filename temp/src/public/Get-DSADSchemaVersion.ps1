function Get-DSADSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSADSchemaVersion.md
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

