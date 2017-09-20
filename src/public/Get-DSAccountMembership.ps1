function Get-DSAccountMembership {
    <#
    .SYNOPSIS
    Get account object group membership.
    .DESCRIPTION
    Get account object group membership in a given directory service.
    .PARAMETER Identity
    Account name to search for.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .PARAMETER BaseFilter
    Unused
    .PARAMETER Limit
    Limits items retrieved. If set to 0 then there is no limit.
    .PARAMETER PageSize
    Items returned per page.
    .PARAMETER SearchRoot
    Root of search.
    .PARAMETER Filter
    LDAP filter for searches.
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
    .PARAMETER LogOnAfter
    Account was logged on after this time. Filters against lastlogontimestamp so this is only valid for timestamps over 14 days old.
    .PARAMETER LogOnBefore
    Account was logged on before this time. Filters against lastlogontimestamp so this is only valid for timestamps over 14 days old.
    .PARAMETER NoPasswordRequired
    Account has no password required set
    .PARAMETER PasswordNeverExpires
    Account has a never expiring password
    .PARAMETER Disabled
    Account is disabled
    .PARAMETER Enabled
    Account is enabled
    .PARAMETER AdminCount
    AdminCount is 1 or greater
    .PARAMETER SPN
    Search for specific SPNs
    .PARAMETER ServiceAccount
    Account is a service account
    .PARAMETER Locked
    Account is locked
    .PARAMETER DotNotAllowDelegation
    Account is not setup for delegation
    .PARAMETER AllowDelegation
    Account is setup for delegation
    .PARAMETER UnconstrainedDelegation
    Account is set for unconstrained delegation
    .PARAMETER MustChangePassword
    Account must change password
    .PARAMETER ChangeLogicOrder
    Alter LDAP filter logic to use OR instead of AND
    .PARAMETER DontJoinAttributeValues
    Output will automatically join the attributes unless this switch is set.
    .PARAMETER IncludeAllProperties
    Include all properties for an object.
    .PARAMETER IncludeNullProperties
    Include unset (null) properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER ExpandUAC
    Expands the UAC attribute into readable format.
    .PARAMETER Raw
    Skip attempts to convert known property types.

    .EXAMPLE
    PS> Get-DSUser -Enabled -PasswordNeverExpires

    Retrieves all users that are enabled and have passwords that never expire.
    .EXAMPLE
    PS> Get-DSUser -Enabled -PasswordNeverExpires -ExpandUAC -IncludeAllProperties

    Same as above but including all user properties and UAC property expansion
    .EXAMPLE
    Get-DSUser -Enabled -PasswordNeverExpires -ExpandUAC -Properties 'Name','Useraccountcontrol'
    Same as above but with a reduced number of properties (which VASTLY speeds up results)
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [switch]$DotNotAllowDelegation,

        [Parameter()]
        [switch]$AllowDelegation,

        [Parameter()]
        [switch]$UnconstrainedDelegation,

        [Parameter()]
        [datetime]$LogOnAfter,

        [Parameter()]
        [datetime]$LogOnBefore,

        [Parameter()]
        [switch]$NoPasswordRequired,

        [Parameter()]
        [switch]$PasswordNeverExpires,

        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [switch]$Enabled,

        [Parameter()]
        [switch]$AdminCount,

        [Parameter()]
        [switch]$ServiceAccount,

        [Parameter()]
        [switch]$MustChangePassword,

        [Parameter()]
        [switch]$Locked
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

        # Most efficient user ldap filter for user accounts: http://www.selfadsi.org/extended-ad/search-user-accounts.htm
        $BaseFilters = @('sAMAccountType=805306368')

        # Logon LDAP filter section
        $LogonLDAPFilters = @()
        if ($LogOnAfter) {
            $LogonLDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
        }
        if ($LogOnBefore) {
            $LogonLDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
        }
        $BaseFilters += Get-CombinedLDAPFilter -Filter $LogonLDAPFilters -Conditional '&'

        # Filter for accounts that are marked as sensitive and can not be delegated.
        if ($DotNotAllowDelegation) {
            $BaseFilters += 'userAccountControl:1.2.840.113556.1.4.803:=1048574'
        }

        if ($AllowDelegation) {
            # negation of "Accounts that are sensitive and not trusted for delegation"
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=1048574)"
        }

        # User has unconstrained delegation set.
        if ($UnconstrainedDelegation) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        # Account is locked
        if ($Locked) {
            $BaseFilters += 'lockoutTime>=1'
        }

        # Filter for accounts who do not requiere a password to logon.
        if ($NoPasswordRequired) {
            $BaseFilters += 'userAccountControl:1.2.840.113556.1.4.803:=32'
        }

        # Filter for accounts whose password does not expires.
        if ($PasswordNeverExpires) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=65536"
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        # Filter for accounts that have SPN set.
        if ($ServiceAccount) {
            $BaseFilters += "servicePrincipalName=*"
        }

        # Filter whose users must change their passwords.
        if ($MustChangePassword) {
            $BaseFilters += 'pwdLastSet=0'
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
        $GetObjectParams.Properties = 'distinguishedname','name','memberof'

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | Foreach {
                $DN = $_.distinguishedname
                $ADObjName = $_.name
                ($_).memberof -split ';' | Foreach {
                    New-Object -TypeName psobject -Property @{
                        'distinguishedname' = $DN
                        'name' = $ADObjName
                        'Group' = $_
                    }
                }
            }
        }
    }
}
