function Get-DSGPO {
    <#
    .SYNOPSIS
    Retreives GPOs as seen by Active Directory
    .DESCRIPTION
    Retreives GPOs as seen by Active Directory
    .PARAMETER Identity
    Name to search for.
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
    .PARAMETER ChangeLogicOrder
    Alter LDAP filter logic to use OR instead of AND
    .PARAMETER Raw
    Skip attempts to convert known property types.
    .PARAMETER DontJoinAttributeValues
    Output will automatically join the attributes unless this switch is set.
    .PARAMETER IncludeAllProperties
    Include all optional properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER ModifiedAfter
    Computer was modified after this time
    .PARAMETER ModifiedBefore
    Computer was modified before this time
    .PARAMETER CreatedAfter
    Computer was created after this time
    .PARAMETER CreatedBefore
    Computer was created before this time
    .PARAMETER UserExtension
    User extension GUIDs to filter on.
    .PARAMETER MachineExtension
    Machine extension GUIDs to filter on.
    .EXAMPLE
    TBD
    .NOTES
    TBD
    .LINK
    TBD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name')]
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

        [Parameter(HelpMessage='Date to search for computers mofied on or after this date.')]
        [datetime]$ModifiedAfter,

        [Parameter(HelpMessage='Date to search for computers mofied on or before this date.')]
        [datetime]$ModifiedBefore,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedAfter,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedBefore,

        [Parameter()]
        [string[]]$UserExtension,

        [Parameter()]
        [string[]]$MachineExtension
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Base filter is the part of this filter that must always be met.
        $BaseFilter = 'objectClass=groupPolicyContainer'
        $LDAPFilters = @()

        # Passed filters are joined with AND logic
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

        # Filter on User Extension Filter.
        if ($UserExtension) {
            $LDAPFilters += "|(gpcuserextensionnames=*{0})" -f ($UserExtension -join '*)(gpcuserextensionnames=*')
        }

        # Filter on Machine Extension Filter.
        if ($MachineExtension) {
            $LDAPFilters += "|(gpcmachineextensionnames=*{0})" -f ($UserExtension -join '*)(gpcmachineextensionnames=*')
        }
    }

    process {
        # Process the last filters here to keep them separated in case they are being passed via the pipeline
        $FinalLDAPFilters = $LDAPFilters
        if ($Identity) {
            $FinalLDAPFilters += "|(name=$($Identity))(displayname=$($Identity))"
        }
        else {
            $FinalLDAPFilters += "name=*"
        }

        $FinalLDAPFilters = $FinalLDAPFilters | Select -Unique
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
