function Get-DSGPO {
    <#
    .SYNOPSIS
    Get computer objects in a given directory service.
    .DESCRIPTION
    Get computer objects in a given directory service. This is just a fancy wrapper for get-dsobject.
    .PARAMETER UserExtension
    User extension GUIDs to filter on.
    .PARAMETER MachineExtension
    Machine extension GUIDs to filter on.
    .EXAMPLE
    PS> Get-DSGPO

    List all GPOs for the current domain.
    .NOTES
    NA
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [string[]]$UserExtension,

        [Parameter()]
        [string[]]$MachineExtension
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
        $BaseFilters = @('objectCategory=groupPolicyContainer')

        # Filter on User Extension Filter.
        if ($UserExtension) {
            $LDAPFilters += "|(gpcuserextensionnames=*{0})" -f ($UserExtension -join '*)(gpcuserextensionnames=*')
        }

        # Filter on Machine Extension Filter.
        if ($MachineExtension) {
            $LDAPFilters += "|(gpcmachineextensionnames=*{0})" -f ($UserExtension -join '*)(gpcmachineextensionnames=*')
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