function Get-DSComputer {
    <#
    .SYNOPSIS
    Get computer objects in a given directory service.
    .DESCRIPTION
    Get computer objects in a given directory service. This is just a fancy wrapper for get-dsobject.
    .PARAMETER Identity
    Computer name to search for.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .PARAMETER Limit
    Limits items retrieved. If set to 0 then there is no limit.
    .PARAMETER PageSize
    Items returned per page.
    .PARAMETER SearchRoot
    Root of search.
    .PARAMETER Filter
    LDAP filter for searches.
    .PARAMETER BaseFilter
    Unused
    .PARAMETER ChangeLogicOrder
    Use logical OR instead of AND in LDAP filtering
    .PARAMETER Properties
    Properties to include in output.
    .PARAMETER SearchScope
    Scope of a search as either a base, one-level, or subtree search, default is subtree.
    .PARAMETER SecurityMask
    Specifies the available options for examining security information of a directory object.
    .PARAMETER TombStone
    Whether the search should also return deleted objects that match the search filter.
    .PARAMETER Raw
    Skip attempts to convert known property types.
    .PARAMETER DontJoinAttributeValues
    Output will automatically join the attributes unless this switch is set.
    .PARAMETER IncludeAllProperties
    Include all properties for an object.
    .PARAMETER IncludeNullProperties
    Include unset (null) properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER TrustedForDelegation
    Computer is trusted for delegation
    .PARAMETER ModifiedAfter
    Computer was modified after this time
    .PARAMETER ModifiedBefore
    Computer was modified before this time
    .PARAMETER CreatedAfter
    Computer was created after this time
    .PARAMETER CreatedBefore
    Computer was created before this time
    .PARAMETER TrustedForDelegation
    Computer is trusted for delegation
    .PARAMETER LogOnAfter
    Computer was logged on after this time
    .PARAMETER LogOnBefore
    Computer was logged on before this time
    .PARAMETER OperatingSystem
    Search for specific Operating Systems
    .PARAMETER Disabled
    Account is disabled
    .PARAMETER Enabled
    Account is enabled
    .PARAMETER SPN
    Search for specific SPNs
    .PARAMETER AdminCount
    AdminCount is 1 or greater
    .EXAMPLE
    Get-DSComputer -OperatingSystem "*windows 7*","*Windows 10*"

    Find all computers in the current domain that are running Windows 7 or Windows 10

    .EXAMPLE
    Get-DSComputer -OperatingSystem "*windows 7*" -Properties name,operatingsystem -LogOnAfter (Get-Date).AddDays(-7)

    Find all computers running windows 7 that have logged in within the last 7 days.
    .EXAMPLE
    Get-DSComputer -LogOnBefore (Get-Date).AddMonths(-3)

    Find all computers that have not logged on to the domain in the last 3 months.

    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(HelpMessage='AdminCount is greater than 0')]
        [switch]$AdminCount,

        [Parameter(HelpMessage='Only those trusted for delegation.')]
        [switch]$TrustedForDelegation,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnAfter,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnBefore,

        [Parameter(HelpMessage='Filter by the specified operating systems.')]
        [string[]]$OperatingSystem,

        [Parameter(HelpMessage='Computer is disabled')]
        [switch]$Disabled,

        [Parameter(HelpMessage='Computer is enabled')]
        [switch]$Enabled,

        [Parameter(HelpMessage='Filter by the specified Service Principal Names.')]
        [string[]]$SPN
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build our base filter (overwrites any dynamic parameter sent base filter)
        $BaseFilters = @('objectCategory=Computer')

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        # Filter for logon time
        if ($LogOnAfter) {
            $BaseFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
        }
        if ($LogOnBefore) {
            $BaseFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
        }

        # Filter by Operating System
        if ($OperatingSystem.Count -ge 1) {
            $BaseFilters += "|(operatingSystem={0})" -f ($OperatingSystem -join ')(operatingSystem=')
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter by Service Principal Name
        if ($SPN.Count -ge 1) {
            $BaseFilters += "|(servicePrincipalName={0})" -f ($SPN -join ')(servicePrincipalName=')
        }

        # Filter for hosts trusted for delegation.
        if ($TrustedForDelegation) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}
