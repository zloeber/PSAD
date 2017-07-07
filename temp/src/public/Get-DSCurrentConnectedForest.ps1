function Get-DSCurrentConnectedForest {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSCurrentConnectedForest.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    if ($Script:CurrentForest -ne $null) {
        return $Script:CurrentForest
    }
    else {
        try {
            Get-DSForest -UpdateCurrent
            return $Script:CurrentForest
        }
        catch {
            Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-ActiveDirectory first."
        }
    }
}

