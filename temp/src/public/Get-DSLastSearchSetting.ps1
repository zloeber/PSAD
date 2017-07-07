function Get-DSLastSearchSetting {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSLastSearchSetting.md
    #>
    [CmdletBinding()]
    param ()

    begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
        return $Script:LastSearchSetting
    }
}

