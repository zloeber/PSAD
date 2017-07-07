function Get-DSDirectorySearcher {
    <#
    .SYNOPSIS
        Get a diresctory searcher object fro a given domain.
    .DESCRIPTION
        Get a diresctory searcher object fro a given domain.
    .PARAMETER ComputerName
        Domain controller to use.
    .PARAMETER Credential
        Credentials to use connection.
    .PARAMETER Limit
        Limits items retrieved. If set to 0 then there is no limit.
    .PARAMETER PageSize
        Items returned per page.
    .PARAMETER SearchRoot
        Root of search.
    .PARAMETER Filter
        LDAP filter for searches.
    .PARAMETER Properties
        Properties to include in output.
    .PARAMETER SearchScope
        Scope of a search as either a base, one-level, or subtree search, default is subtree.
    .PARAMETER SecurityMask
        Specifies the available options for examining security information of a directory object.
    .PARAMETER TombStone
        Whether the search should also return deleted objects that match the search filter.
    .EXAMPLE
        C:\PS> $ADSearcher = Get-DSDirectorySearcher -Filter '(&(objectCategory=computer)(servicePrincipalName=MSSQLSvc*))'
        Create a DirectorySearcher object with a filter for searching for all computers with a servicePrincipalName for Microsoft SQL Server.
    .OUTPUTS
        System.DirectoryServices.DirectorySearcher
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter = 'name=*',

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    process {
        switch ( $ADConnectState ) {
            { @('AltUserAndServer', 'CurrentUserAltServer', 'AltUser') -contains $_ } {
                Write-Verbose "$($FunctionName): Alternate user and/or server."
                if ($searchRoot.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -DistinguishedName $searchRoot -Credential $Credential

                }
                else {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -Credential $Credential
                }
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ($searchRoot.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -DistinguishedName $searchRoot
                }
                else {
                    $domObj = Get-DSDirectoryEntry
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }

        if (-not [string]::IsNullOrEmpty($Filter)) {
            Write-Verbose "$($FunctionName): Joining ldap filters, total filters = $($Filter.Count)."
            $LDAP = "(&({0}))" -f ($Filter -join ')(')
            Write-Verbose "$($FunctionName): LDAP filter = $LDAP"
        }

        $objSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList @($domObj, $LDAP, $Properties) -Property @{
            PageSize = $PageSize
            SearchScope = $SearchScope
            Tombstone = $TombStone
            SecurityMasks = [System.DirectoryServices.SecurityMasks]$SecurityMask
            CacheResults = $false
        }

        if ($SizeLimit -ne 0) {
            Write-Verbose "$($FunctionName): Limiting search results to $Limit"
            $objSearcher.SizeLimit = $Limit
        }

        $objSearcher
    }
}
