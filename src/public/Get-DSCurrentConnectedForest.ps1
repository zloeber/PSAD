function Get-DSCurrentConnectedForest {
    <#
    .SYNOPSIS
    Gets the currently connected forest information.
    .DESCRIPTION
    Gets the currently connected forest information.
    .EXAMPLE
    PS> Get-DSCurrentConnectedForest
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
   #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    if ($Script:CurrentForest -ne $null) {
        return $Script:CurrentForest
    }
    else {
        try {
            Get-DSForest -UpdateCurrent
            return $Script:CurrentForest
        }
        catch {
            Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-ActiveDirectory first."
        }
    }
}
