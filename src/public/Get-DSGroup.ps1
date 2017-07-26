function Get-DSGroup {
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
    .PARAMETER Category
    Group category, either security or distribution
    .PARAMETER AdminCount
    AdminCount is 1 or greater
    .PARAMETER Empty
    Include only empty groups
    .EXAMPLE
    PS> Get-DSGroup 'Domain Admins'

    Returns the 'domain admins' group for the current domain.
    .EXAMPLE
    PS> get-dsgroup -Properties name,groupcategory,groupscope -empty

    Returns all empty groups along with their scope and category

    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [ValidateSet('Security','Distribution')]
        [string]$Category,

        [Parameter()]
        [switch]$AdminCount,

        [Parameter()]
        [switch]$Empty

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
        $BaseFilters = @('objectCategory=Group')

        # Filter by category
        if ($Category) {
            switch ($category) {
                'Distribution' {
                    $BaseFilters += '!(groupType:1.2.840.113556.1.4.803:=2147483648)'
                }
                'Security' {
                    $BaseFilters += 'groupType:1.2.840.113556.1.4.803:=2147483648'
                }
            }
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        if ($Empty) {
            $BaseFilters += "!(member=*)"
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
