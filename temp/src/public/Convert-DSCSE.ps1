function Convert-DSCSE {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Convert-DSCSE.md
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$CSEString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    $CSEString = $CSEString -replace '}{','},{'
    ($Script:GPOGuidRef).keys | Foreach-Object {
        $CSEString = $CSEString -replace $_,$GPOGuidRef[$_]
    }

    $CSEString
}

