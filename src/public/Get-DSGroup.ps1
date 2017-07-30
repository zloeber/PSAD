function Get-DSGroup {
    <#
    .SYNOPSIS
    Get group objects in a given directory service.
    .DESCRIPTION
    Get group objects in a given directory service. This is just a fancy wrapper for get-dsobject.
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
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
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
