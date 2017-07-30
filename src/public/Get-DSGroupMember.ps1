function Get-DSGroupMember {
    <#
    .SYNOPSIS
    Return all members of a group.
    .DESCRIPTION
    Return all members of a group.
    .PARAMETER Recurse
    Return all members of a group, even if they are in another group.
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

        # Create a splat with only Get-DSObject parameters
        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }

        # Store another copy of the splat for later member lookup
        $GetMemberParams = $GetObjectParams.Clone()
        $GetMemberParams.Identity = $null

        $Identities += $Identity
    }

    end {
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for group: $ID"
            $GetObjectParams.Identity = $ID
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
