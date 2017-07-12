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
    Include all optional properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
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
    .PARAMETER ChangeLogicOrder
    Use logical OR instead of AND in LDAP filtering
    .EXAMPLE
    TBD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Group','Name')]
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
        [switch]$Raw,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [datetime]$ModifiedAfter,

        [Parameter()]
        [datetime]$ModifiedBefore,

        [Parameter()]
        [datetime]$CreatedAfter,

        [Parameter()]
        [datetime]$CreatedBefore,

        [Parameter()]
        [ValidateSet('Security','Distribution')]
        [string]$Category,

        [Parameter()]
        [switch]$AdminCount
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build filter
        $CompLDAPFilter = 'objectCategory=Group'
        $LDAPFilters = @()

        if ($Filter.Count -ge 1) {
            $LDAPFilters += "(&({0}))" -f ($Filter -join ')(')
        }

        # Filter for modification time
        if ($ModifiedAfter -and $ModifiedBefore) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ')))(whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($ModifiedAfter) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($ModifiedBefore) {
            $LDAPFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for creation time
        if ($CreatedAfter -and $CreatedBefore) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ')))(whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($CreatedAfter) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($CreatedBefore) {
            $LDAPFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        if ($Identity) {
            $Identity = Format-ADSearchFilterValue -String $Identity
            $LDAPFilters += "|(name=$($Identity))(sAMAccountName=$($Identity))(cn=$($Identity))"
        }
        else {
            $LDAPFilters += 'name=*'
        }
       # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $LDAPFilters += "admincount>=1"
        }

        # Filter by category
        if ($Category) {
            switch ($category) {
                'Distribution' {
                    $LDAPFilters += '!(groupType:1.2.840.113556.1.4.803:=2147483648)'
                }
                'Security' {
                    $LDAPFilters += 'groupType:1.2.840.113556.1.4.803:=2147483648'
                }
            }
        }

        $LDAPFilters = $LDAPFilters | Select -Unique

        if ($ChangeLogicOrder) {
            $GroupFilter = "(&($CompLDAPFilter)(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            $GroupFilter = "(&($CompLDAPFilter)(&({0})))" -f ($LDAPFilters -join ')(')
        }
    }

    process {
        Write-Verbose "$($FunctionName): Searching with filter: $GroupFilter"

         $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            Filter = $GroupFilter
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
