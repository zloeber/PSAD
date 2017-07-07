function Get-DSSchema {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSSchema.md
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

