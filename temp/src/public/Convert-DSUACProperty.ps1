function Convert-DSUACProperty {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Convert-DSUACProperty.md
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$UACProperty
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    try {
        $UAC = [Enum]::Parse('userAccountControlFlags', $UACProperty)
        $Script:UACAttribs | Foreach-Object {
            if ($UAC -match $_) {
                $_
            }
        }
    }
    catch {
        Write-Warning -Message ("$($FunctionName) {0}" -f $_.Exception.Message)
    }
}

