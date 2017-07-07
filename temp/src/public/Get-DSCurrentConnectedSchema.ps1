function Get-DSCurrentConnectedSchema {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSCurrentConnectedSchema.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    if ($Script:CurrentSchema -ne $null) {
        return $Script:CurrentSchema
    }
    else {
        try {
            Get-DSSchema -UpdateCurrent
            return $Script:CurrentSchema
        }
        catch {
            Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-DSAD first."
        }
    }
}

