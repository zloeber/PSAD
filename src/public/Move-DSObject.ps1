function Move-DSObject {
    <#
    .SYNOPSIS
    Moves AD objects to a destination OU.
    .DESCRIPTION
    Moves AD objects to a destination OU. This will move ANY object that is able to be found with the filter you use so be careful when using this command.
    .PARAMETER Destination
    Desination OU to move objects into.
    .PARAMETER Force
    Force move to OU without confirmation.
    .EXAMPLE
    TBD
    .NOTES
    NA
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [Alias('OU','TargetPath')]
        [string]$Destination,

        [Parameter(HelpMessage = 'Force move to OU without confirmation.')]
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
        }

        # If the destination OU doesn't exist then there is nothing for us to do...
        if (-not (Test-DSObjectPath -Path $Destination @SearcherParams)) {
            throw "$($FunctionName): Destination OU doesn't seem to exist: $Destination"
        }
        else {
            # Otherwise get a DE of the destination OU for later
            Write-Verbose "$($FunctionName): Retreiving DN of the OU at $Destination"
            $OU = Get-DSDirectoryEntry @SearcherParams -DistinguishedName $Destination
        }

        $GetObjectParams.ResultsAs = 'DirectoryEntry'

        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | ForEach-Object {
                $Name = $_.Properties['name']
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Move AD Object $Name to $Destination", "Move AD Object $Name to $Destination?","Moving AD Object $Name")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to move '$Name'?", "Moving AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            $_.MoveTo($OU)
                        }
                        catch {
                            $ThisError = $_
                            Write-Error "$($FunctionName): Unable to move $Name - $ThisError"
                        }
                    }
                }
            }
        }
    }
}
