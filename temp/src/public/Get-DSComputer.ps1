function Get-DSComputer {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSComputer.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Computer','Name')]
        [string]$Identity,

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
        [string[]]$Filter,

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
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [switch]$Raw,

        [Parameter(HelpMessage='Only those trusted for delegation.')]
        [switch]$TrustedForDelegation,

        [Parameter(HelpMessage='Date to search for computers mofied on or after this date.')]
        [datetime]$ModifiedAfter,

        [Parameter(HelpMessage='Date to search for computers mofied on or before this date.')]
        [datetime]$ModifiedBefore,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedAfter,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedBefore,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnAfter,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnBefore,

        [Parameter(HelpMessage='Filter by the specified operating systems.')]
        [SupportsWildcards()]
        [string[]]$OperatingSystem,

        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [switch]$Enabled,

        [Parameter(HelpMessage='Filter by the specified Service Principal Names.')]
        [SupportsWildcards()]
        [string[]]$SPN
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build filter
        $BaseFilter = 'objectCategory=Computer'
        $LDAPFilters = @()

        if ($Filter.Count -ge 1) {
            $LDAPFilters += "(&({0}))" -f ($Filter -join ')(')
        }

        # Filter for modification time
        if ($ModifiedAfter) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($ModifiedBefore) {
            $LDAPFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for creation time
        if ($CreatedAfter) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($CreatedBefore) {
            $LDAPFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for logon time
        if ($LogOnAfter) {
            $LDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
            #$LDAPFilters +=  "lastlogon>=$($LogOnAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($LogOnBefore) {
            $LDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
            #$LDAPFilters += "lastlogon<=$($LogOnBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter by Operating System
        if ($OperatingSystem.Count -ge 1) {
            $OSFilter = "|(operatingSystem={0})" -f ($OperatingSystem -join ')(operatingSystem=')
            $LDAPFilters += $OSFilter
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $LDAPFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter by Service Principal Name
        if ($SPN.Count -ge 1) {
           $SPNFilter = "|(servicePrincipalName={0})" -f ($SPN -join ')(servicePrincipalName=')
           $LDAPFilters += $SPNFilter
        }

        # Filter for hosts trusted for delegation.
        if ($TrustedForDelegation) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }
    }

    process {
        # Process the last filters here to keep them separated in case they are being passed via the pipeline
        $FinalLDAPFilters = $LDAPFilters
        if ($Identity) {
            $FinalLDAPFilters += "name=$($Identity)"
        }
        else {
            $FinalLDAPFilters += "name=*"
        }

        $FinalLDAPFilters = @($FinalLDAPFilters | Select-Object -Unique)
        if ($ChangeLogicOrder) {
            # Join filters with logical OR
            $FinalFilter = "(&($BaseFilter)(|({0})))" -f ($FinalLDAPFilters -join ')(')
        }
        else {
            # Join filters with logical AND
            $FinalFilter = "(&($BaseFilter)(&({0})))" -f ($FinalLDAPFilters -join ')(')
        }
        Write-Verbose "$($FunctionName): Searching with filter: $FinalFilter"

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            Filter = $FinalFilter
            Properties = $Properties
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }
        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }
        if ($IncludeAllProperties) {
            $SearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $SearcherParams.DontJoinAttributeValues = $true
        }
        if ($Raw) {
            $SearcherParams.Raw = $true
        }
        Get-DSObject @SearcherParams
    }
}

