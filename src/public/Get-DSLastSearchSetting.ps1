function Get-DSLastSearchSetting {
    <#
    .SYNOPSIS
    Returns the last used directory search settings.
    .DESCRIPTION
    Returns the last used directory search settings. Good for learning or troubleshooting.
    .EXAMPLE
    PS> Get-DSLastSearchSetting

    Displays the LDAP filter, scope, base, and other parameters used in the last call to Get-DSObject.
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
        return $Script:LastSearchSetting
    }
}
