function Convert-DSPwdProperty {
    <#
    .SYNOPSIS
    Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties
    .DESCRIPTION
    Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties. More of a helper function.
    .PARAMETER PwdProperties
    User account control data to process.
    .EXAMPLE
    Get-DSObject 'dc=contoso,dc=com' -IncludeAllProperties | Convert-DSPwdProperty
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    author: Zachary Loeber
    Further information:
    https://msdn.microsoft.com/en-us/library/ms679431(v=vs.85).aspx
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$PwdProperties
    )
    if ($Script:ThisModuleLoaded) {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    try {
        $Props = [Enum]::Parse('DomainPwdPropertiesFlags', $PwdProperties)
        $Script:PwdPropertyAttribs | Foreach-Object {
            if ($Props -match $_) {
                $_
            }
        }
    }
    catch {
        Write-Warning -Message ("$($FunctionName) {0}" -f $_.Exception.Message)
    }
}