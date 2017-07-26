function Get-CommonSearcherParams {
    <#
    .SYNOPSIS
    Constuct parameters for the most common searches.
    .DESCRIPTION
    Constuct search parameters from the most common PSAD parameters. This creates a hashtable
    suitable for get-dsdirectorysearcher.
    .PARAMETER Identity
    AD object to search for.
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
    User passed LDAP filter for searches.
    .PARAMETER BaseFilter
    Other LDAP filters for specific searches (like user or computer)
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
    .PARAMETER IncludeAllProperties
    Include all properties for an object.
    .PARAMETER IncludeNullProperties
    Include unset (null) properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER ModifiedAfter
    Account was modified after this time
    .PARAMETER ModifiedBefore
    Account was modified before this time
    .PARAMETER CreatedAfter
    Account was created after this time
    .PARAMETER CreatedBefore
    Account was created before this time
    .PARAMETER ChangeLogicOrder
    Alter LDAP filter logic to use OR instead of AND
    .PARAMETER DontJoinAttributeValues
    Output will automatically join the attributes unless this switch is set.
    .PARAMETER ExpandUAC
    Expands the UAC attribute into readable format.
    .PARAMETER Raw
    Skip attempts to convert known property types.
    .EXAMPLE
    NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter( Position = 0 )]
        [Alias('User', 'Name', 'sAMAccountName', 'distinguishedName')]
        [string]$Identity,

        [Parameter( Position = 1 )]
        [Alias('Server', 'ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position = 2 )]
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
        [string]$BaseFilter,

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
        [bool]$TombStone,

        [Parameter()]
        [bool]$IncludeAllProperties,

        [Parameter()]
        [bool]$IncludeNullProperties,

        [Parameter()]
        [bool]$ChangeLogicOrder,

        [Parameter()]
        $ModifiedAfter,

        [Parameter()]
        $ModifiedBefore,

        [Parameter()]
        $CreatedAfter,

        [Parameter()]
        $CreatedBefore
    )

    # Function initialization
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    # Generate additional groups of filters to add to the LDAP filter set
    #  these will always be logically ANDed with the custom filters
    $LDAPFilters = @()

    if ($ChangeLogicOrder) {
        Write-Verbose "$($FunctionName): Setting logic order for custom filters to OR."
        $AndOr = '|'
    }
    else {
        Write-Verbose "$($FunctionName): Setting logic order for custom filters to AND."
        $AndOr = '&'
    }

    $LDAPFilters += Get-CombinedLDAPFilter -Filter $Filter -Conditional $AndOr

    # Create a set of other filters based on the passed parameters
    $ModifiedFilters = @()

    # Filter for modification time
    if ($ModifiedAfter) {
        $ModifiedFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
    }
    if ($ModifiedBefore) {
        $ModifiedFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
    }

    $LDAPFilters += Get-CombinedLDAPFilter -Filter $ModifiedFilters -Conditional '&'

    # Filter for creation time
    $CreatedFilters = @()
    if ($CreatedAfter) {
        $CreatedFilters += "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
    }
    if ($CreatedBefore) {
        $CreatedFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
    }
    $LDAPFilters += Get-CombinedLDAPFilter -Filter $CreatedFilters -Conditional '&'

    if (-not [string]::IsNullOrEmpty($Identity)) {
        Write-Verbose "$($FunctionName): Identity was passed ($Identity), creating filter"
        $LDAPFilters += Get-CommonIDLDAPFilter -Identity $Identity -Filter $Filter
    }

    $LDAPFilters += $BaseFilter

    $FinalLDAPFilters = Get-CombinedLDAPFilter -Filter $LDAPFilters -Conditional '&'

    if ($null -eq $FinalLDAPFilters) {
        $FinalLDAPFilters = '(distinguishedName=*)'
    }
    Write-Verbose "$($FunctionName): Final LDAPFilter string = $FinalLDAPFilters"

    $SearcherParams = @{
        ComputerName = $ComputerName
        SearchRoot = $searchRoot
        SearchScope = $SearchScope
        Limit = $Limit
        Credential = $Credential
        Filter = $FinalLDAPFilters
        Properties = $Properties
        PageSize = $PageSize
        SecurityMask = $SecurityMask
    }
    if ($Tombstone) {
        Write-Verbose "$($FunctionName): Including tombstone items"
        $SearcherParams.Tombstone = $true
    }

    # If all properties are being returned then we have nothing more to do
    if ($IncludeAllProperties) {
        Write-Verbose "$($FunctionName): Including all properties"
        $SearcherParams.Properties = '*'
    }
    else {

        # Otherwise we need to maybe add different properties which are used to derive other properties
        if ($IncludeNullProperties) {
            Write-Verbose "$($FunctionName): Including null properties"
            # To derive null properties we need the objectClass for the schema lookup.
            if (($SearcherParams.Properties -notcontains 'objectClass') -and ($SearcherParams.Properties -ne '*')) {
                $SearcherParams.Properties += 'objectClass'
            }
        }

        # if we are including some non-standard group properties then add grouptype so we can derive them
        if (($SearcherParams.Properties -contains 'GroupScope') -or ($SearcherParams.Properties -contains 'GroupCategory')) {
            if ($SearcherParams.Properties -notcontains 'grouptype') {
                $SearcherParams.Properties += 'grouptype'
            }
        }
    }

    Write-Verbose "$($FunctionName): $(New-Object psobject -Property $SearcherParams)"
    return $SearcherParams
}
