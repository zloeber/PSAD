function Format-DSSearchFilterValue {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Format-DSSearchFilterValue.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $SearchString = $SearchString.Replace('\', '\5c')
    $SearchString = $SearchString.Replace('*', '\2a')
    $SearchString = $SearchString.Replace('(', '\28')
    $SearchString = $SearchString.Replace(')', '\29')
    $SearchString = $SearchString.Replace('/', '\2f')
    $SearchString.Replace("`0", '\00')
}

