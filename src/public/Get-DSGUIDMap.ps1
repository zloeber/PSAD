function Get-DSGUIDMap {
    <#
    .SYNOPSIS
    Retrieves the module internal GUIDMap hash (if it has been populated)
    .DESCRIPTION
    Retrieves the module internal GUIDMap hash (if it has been populated)
    .EXAMPLE
    Get-DSGUIDMap
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
   #>
    [CmdletBinding()]
    param ()

    begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
        return $Script:GUIDMap
    }
}
