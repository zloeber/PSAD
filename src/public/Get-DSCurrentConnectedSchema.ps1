function Get-DSCurrentConnectedSchema {
    <#
    .SYNOPSIS
    Gets the currently connected forest schema information.
    .DESCRIPTION
    Gets the currently connected forest schema information.
    .EXAMPLE
    PS> Get-DSCurrentConnectedSchema
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
   #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    if ($Script:CurrentSchema -ne $null) {
        return $Script:CurrentSchema
    }
    else {
        try {
            Get-DSSchema -UpdateCurrent
            return $Script:CurrentSchema
        }
        catch {
            Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-DSAD first."
        }
    }
}
