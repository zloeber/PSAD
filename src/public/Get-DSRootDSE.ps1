function Get-DSRootDSE {
    <#
    .SYNOPSIS
    Retrieves the RootDSE of a forest.
    .DESCRIPTION
    Retrieves the RootDSE of a forest.
    .EXAMPLE
    PS> Get-DSRootDSE

    Retrieves the current RootDSE directory entry.
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSDirectoryEntry' -CommandType 'Function'
    }
    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

    }
    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetDEParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSDirectoryEntryParameters -contains $_) } | Foreach-Object {
            $GetDEParams.$_ = $PSBoundParameters.$_
        }
        Write-Verbose "$($FunctionName): Directory Entry Search Parameters = $($GetDEParams)"
        $GetDEParams.DistinguishedName = 'rootDSE'

        try {
            Get-DSDirectoryEntry @GetDEParams
        }
        catch {
            throw $_
        }
    }
}
