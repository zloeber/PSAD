function Get-DSADSite {
    <#
    .SYNOPSIS
    Retreives the AD site information
    .DESCRIPTION
    Retreives the AD site information
    .PARAMETER Forest
    Forest name to retreive site from.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .EXAMPLE
    PS> Get-DSADSite

    Returns the sites found in the current forest
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [Alias('Name','Identity','ForestName')]
        [string]$Forest = ($Script:CurrentForest).name,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
    }

    end {
        try {
            (Get-DSForest -Identity $Forest @DSParams).Sites
        }
        catch {
            Write-Warning "$($FunctionName): Unable to get AD site information from the forest."
        }
    }
}
