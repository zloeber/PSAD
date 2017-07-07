function Get-DSUser {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSUser.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('User','Name')]
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

        [Parameter()]
        [switch]$ExpandUAC,

        [Parameter()]
        [switch]$DotNotAllowDelegation,

        [Parameter()]
        [switch]$AllowDelegation,

        [Parameter()]
        [switch]$UnconstrainedDelegation,

        [Parameter()]
        [datetime]$ModifiedAfter,

        [Parameter()]
        [datetime]$ModifiedBefore,

        [Parameter()]
        [datetime]$CreatedAfter,

        [Parameter()]
        [datetime]$CreatedBefore,

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

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Most efficient user ldap filter for user accounts: http://www.selfadsi.org/extended-ad/search-user-accounts.htm
        $BaseFilter = 'sAMAccountType=805306368'
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

        if ($LogOnAfter) {
            $LDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
            #$LDAPFilters +=  "lastlogon>=$($LogOnAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($LogOnBefore) {
            $LDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
            #$LDAPFilters += "lastlogon<=$($LogOnBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for accounts that are marked as sensitive and can not be delegated.
        if ($DotNotAllowDelegation) {
            $LDAPFilters += 'userAccountControl:1.2.840.113556.1.4.803:=1048574'
        }

        if ($AllowDelegation) {
            # negation of "Accounts that are sensitive and not trusted for delegation"
            $LDAPFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=1048574)"
        }

        # User has unconstrained delegation set.
        if ($UnconstrainedDelegation) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        # Account is locked
        if ($Locked) {
            $LDAPFilters += 'lockoutTime>=1'
        }

        # Filter for accounts who do not requiere a password to logon.
        if ($NoPasswordRequired) {
            $LDAPFilters += 'userAccountControl:1.2.840.113556.1.4.803:=32'
        }

        # Filter for accounts whose password does not expires.
        if ($PasswordNeverExpires) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=65536"
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $LDAPFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $LDAPFilters += "admincount>=1"
        }

        # Filter for accounts that have SPN set.
        if ($ServiceAccount) {
            $LDAPFilters += "servicePrincipalName=*"
        }

        # Filter whose users must change their passwords.
        if ($MustChangePassword) {
            $LDAPFilters += 'pwdLastSet=0'
        }

        $LDAPFilters = @($LDAPFilters | Select-Object -Unique)
        if ($ChangeLogicOrder) {
            $UserFilter = "(&($UserLDAPFilter)(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            $UserFilter = "(&($UserLDAPFilter)(&({0})))" -f ($LDAPFilters -join ')(')
        }
    }

    process {
        # Process the last filters here to keep them separated in case they are being passed via the pipeline
        $FinalLDAPFilters = $LDAPFilters

        if ($Identity) {
            $FinalLDAPFilters += "|(name=$($Identity))(sAMAccountName=$($Identity))(cn=$($Identity))(DisplayName=$($Identity))"
        }
        else {
            $FinalLDAPFilters += 'sAMAccountName=*'
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
        if ($ExpandUAC) {
            $SearcherParams.ExpandUAC = $true
        }
        if ($Raw) {
            $SearcherParams.Raw = $true
        }

        Get-DSObject @SearcherParams
    }
}

