function Get-DSGroupMember {
    <#
    .SYNOPSIS
    Return all members of a group.
    .DESCRIPTION
    Return all members of a group.
    .PARAMETER Identity
    Computer name to search for.
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
    .PARAMETER Recurse
    Computer was modified after this time
    .EXAMPLE
    PS> Get-DSGroupMember -Identity 'Domain Admins' -recurse -Properties *

    Retrieves all domain admin group members, including those within embedded groups along with all their properties.
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [switch]$Recurse
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
        $GetMemberParams = $GetObjectParams.Clone()
        $GetMemberParams.Identity = $null

        $Identities += $Identity
    }

    end {
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for group: $ID"
            $GetObjectParams.Identity = $ID
            $OriginalProperties = $GetObjectParams.Properties
            $GetObjectParams.Properties = 'distinguishedname'

            try {
                $GroupDN = (Get-DSGroup @GetObjectParams).distinguishedname
                if ($Recurse) {
                    $GetMemberParams.BaseFilter += "memberof:1.2.840.113556.1.4.1941:=$GroupDN"
                }
                else {
                    $GetMemberParams.BaseFilter += "memberof=$GroupDN"
                }

                Get-DSObject @GetMemberParams
            }
            catch {
                Write-Warning "$($FunctionName): Unable to find group with ID of $ID"
            }
        }
    }
}
