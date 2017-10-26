function Get-DSExchangeSchemaVersion {
    <#
    .SYNOPSIS
    Retreives the Exchange schema version in human readable format.
    .DESCRIPTION
    Retreives the Exchange schema version in human readable format.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .EXAMPLE
    PS> Get-DSExchangeSchemaVersion

    Returns the exchange version found in the current forest.
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
    }

    process {
        try {
            $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
            $RangeUpper = (Get-DSObject -SearchRoot "CN=ms-Exch-Schema-Version-Pt,CN=Schema,$($rootDSE.configurationNamingContext)" -Properties 'rangeUpper' @DSParams).rangeUpper
            if (($Script:SchemaVersionTable).Keys -contains $RangeUpper) {
                $SchemaVersion = $Script:SchemaVersionTable[$RangeUpper]
            }
            else {
                $SchemaVersion = 'Unknown'
            }

            $ObjectVersion = (Get-DSObject -SearchRoot "CN=Microsoft Exchange System Objects,$($RootDSE.defaultNamingContext)" -Properties 'objectVersion' @DSParams).objectVersion
            $AdminGroups = @(Get-DSObject -Filter 'msExchAdminGroupsEnabled=*' -SearchRoot $RootDSE.configurationNamingContext @DSParams)
            Write-Verbose "$($FunctionName): Admin groups found - $($AdminGroup.Count)"

            $VersionInfo = @()
            Foreach ($AdminGroup in $AdminGroups) {
                Write-Verbose "$($FunctionName): Retrieving version information for $($AdminGroup.Name)"
                $VersionInfo += New-Object -TypeName PSObject -Property @{
                    'AdminGroup' = $AdminGroup.Name
                    'AdminGroupProductID' = (Get-DSObject -SearchRoot $AdminGroup.distinguishedName -Properties 'msExchProductId' -SearchScope:Base @DSParams).msExchProductId
                    'AdminGroupObjectVersion' = (Get-DSObject -SearchRoot $AdminGroup.distinguishedName  -Properties 'ObjectVersion' @DSParams).ObjectVersion
                    'ms-Exch-Schema-Version-Pt' = $RangeUpper
                    'SchemaVersion' = $SchemaVersion
                }
            }
        }
        catch {
            throw
        }

        $VersionInfo
    }
}
