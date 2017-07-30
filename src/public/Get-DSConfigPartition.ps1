function Get-DSConfigPartition {
    <#
    .SYNOPSIS
    Retrieves information about the configuration partition.
    .DESCRIPTION
    Retrieves information about the configuration partition.
    .EXAMPLE
    PS> Get-DSConfigPartition

    Retrieves the current configuration partition
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

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

        $GetDEParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSDirectoryEntryParameters -contains $_) } | Foreach-Object {
            $GetDEParams.$_ = $PSBoundParameters.$_
        }
        Write-Verbose "$($FunctionName): Directory Entry Search Parameters = $($GetDEParams)"
        $GetDEParams.DistinguishedName = 'rootDSE'

        try {
            $RootDSE = Get-DSDirectoryEntry @GetDEParams
            $GetObjectParams.SearchRoot = $rootDSE.configurationNamingContext
            $GetObjectParams.Identity = $Null
            $GetObjectParams.SearchScope = 'Base'
            $GetObjectParams.Properties = 'name','adspath','distinguishedname'

            Get-DSObject @GetObjectParams
        }
        catch {
            throw $_
        }
    }
}
