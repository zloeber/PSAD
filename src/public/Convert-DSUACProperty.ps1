function Convert-DSUACProperty {
    <#
    .SYNOPSIS
    Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties
    .DESCRIPTION
    Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties. More of a helper function.
    .PARAMETER UACProperty
    User account control data to process.
    .EXAMPLE
    (Get-DSUser Administrator -Raw -Properties * ).useraccountcontrol | Convert-DSUACProperty
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    author: Zachary Loeber
    Further information:
        http://support.microsoft.com/kb/305144
        http://msdn.microsoft.com/en-us/library/cc245514.aspx
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
