function Get-DSExchangeSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSExchangeSchemaVersion.md
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
        try {
            $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' -ComputerName $ComputerName -Credential $Credential
            $RangeUpper = (Get-DSObject -SearchRoot "CN=ms-Exch-Schema-Version-Pt,CN=Schema,$($rootDSE.configurationNamingContext)" -Properties 'rangeUpper' -ComputerName $ComputerName -Credential $Credential).rangeUpper

            if (($Script:SchemaVersionTable).Keys -contains $RangeUpper) {
                Write-Verbose "$($FunctionName): Exchange schema version found."
                $Script:SchemaVersionTable[$RangeUpper]
            }
            else {
                Write-Verbose "$($FunctionName): Exchange schema version not in our list."
                $RangeUpper
            }
        }
        catch {
            return $null
        }
    }
}

