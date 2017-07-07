function Set-DSPageSize {
    <#
    .SYNOPSIS
    Sets module variable containing the currently used page size for AD queries.
    .DESCRIPTION
    Sets module variable containing the currently used page size for AD queries.
    .PARAMETER PageSize
    Pagesize to set.
    .EXAMPLE
    PS> Set-DSPageSize -PageSize 1000
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
   #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]$PageSize = 1000
    )

    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $Script:PageSize = $PageSize
}
