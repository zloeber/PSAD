function Remove-DSGroupMember {
    <#
    .SYNOPSIS
    Removes AD objects to a specified group.
    .DESCRIPTION
    Removes AD objects to a specified group.
    .PARAMETER Group
    Group name to remove accounts as a member of.
    .PARAMETER Force
    Force remove account from group membership without confirmation.
    .EXAMPLE
    PS> get-dsuser jdoe | Remove-DSGroupMember -Group 'Sales Team' -force

    Removes jdoe to the 'Sales Team' group without prompting for confirmation.
    .NOTES
    It is best to pipe users in via get-dsuser or get-dscomputer where possible.
    This function is missing -Whatif implementation at this time.
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [Alias('GroupName')]
        [string]$Group,

        [Parameter(HelpMessage = 'Force add group membership.')]
        [Switch]$Force
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
        $YesToAll = $false
        $NoToAll = $false
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
        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'DirectoryEntry'
            Identity = $Group
        }

        try {
            # Otherwise get a DE of the group for later
            Write-Verbose "$($FunctionName): Retreiving directory entry of the group - $Group"
            $GroupDE = @(Get-DSGroup @SearcherParams)
        }
        catch {
            throw "Unable to get a directory entry for the specified group of $Group"
        }

        if ($GroupDE.Count -gt 1) {
            throw "More than one group result was found for $Group, exiting!"
        }
        else {
            $GroupDE = $GroupDE[0]
        }

        $GetObjectParams.Properties = 'adspath','name'

        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | ForEach-Object {
                $Name = $_.name
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Remove $Name to $Group", "Remove $Name from $Group?","Removing $Name from $Group")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to remove '$Name'?", "Removing $Name from $Group", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            $GroupDE.Remove($_.adspath)
                        }
                        catch {
                            $ThisError = $_
                            Write-Warning "$($FunctionName): Unable to remove $Name to $Group"
                        }
                    }
                }
            }
        }
    }
}
