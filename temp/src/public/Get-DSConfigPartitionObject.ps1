function Get-DSConfigPartitionObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSConfigPartitionObject.md
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
        $Credential = $Script:CurrentCredential,

        [Parameter(Position = 2)]
        [string]$SearchPath,
        
        [Parameter(Position = 3)]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter(Position = 4)]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Base'
    )
    
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    
    process {
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' -ComputerName $ComputerName -Credential $Credential

        if ($SearchPath) {
            Get-DSObject -SearchRoot "$SearchPath,$($rootDSE.configurationNamingContext)" -Properties $Properties -ComputerName $ComputerName -Credential $Credential -SearchScope:$SearchScope
        }
        else {
            Get-DSObject -SearchRoot "$($rootDSE.configurationNamingContext)" -Properties $Properties -ComputerName $ComputerName -Credential $Credential -SearchScope:$SearchScope
        }
    }
}

