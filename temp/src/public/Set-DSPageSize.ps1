function Set-DSPageSize {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Set-DSPageSize.md
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

