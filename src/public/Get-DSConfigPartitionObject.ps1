function Get-DSConfigPartitionObject {
    <#
    .SYNOPSIS
        A helper function for retreiving a configuration partition object.
    .DESCRIPTION
        A helper function for retreiving a configuration partition object.
    .PARAMETER ComputerName
        Domain controller to use for this search.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .PARAMETER SearchPath
        Additional path to retreive (ie. CN=ms-Exch-Schema-Version-Pt,CN=Schema)
    .PARAMETER Properties
        Properties to retreive.
    .PARAMETER SearchScope
        Scope of a search as either a base, one-level, or subtree search, default is base.
    .EXAMPLE
        PS> Get-DSConfigPartitionObject -SearchPath 'CN=ms-Exch-Schema-Version-Pt,CN=Schema' -Properties '*'

        Returns the exchange version found in the current forest.
    .EXAMPLE
        PS> Get-DSConfigPartitionObject -SearchPath 'CN=Certification Authorities,CN=Public Key Services,CN=Services' -SearchScope:OneLevel -Properties 'name'

        Lists all forest enterprise certificate authorities
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
