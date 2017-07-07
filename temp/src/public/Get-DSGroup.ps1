function Get-DSGroup {
   <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSGroup.md
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

