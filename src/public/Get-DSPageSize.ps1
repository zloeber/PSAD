function Get-DSPageSize {
    <#
    .SYNOPSIS
    Returns module variable containing the currently used page size for AD queries.
    .DESCRIPTION
    Returns module variable containing the currently used page size for AD queries.
    .EXAMPLE
    PS> Get-DSPageSize
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
   #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    return $Script:PageSize
}
