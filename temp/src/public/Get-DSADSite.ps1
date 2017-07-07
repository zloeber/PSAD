function Get-DSADSite {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSADSite.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [Alias('Name','Identity','ForestName')]
        [string]$Forest = ($Script:CurrentForest).name,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
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
    }

    end {
        try {
            (Get-DSForest -Identity $Forest @DSParams).Sites
        }
        catch {
            Write-Warning "$($FunctionName): Unable to get AD site information from the forest."
        }
    }
}

