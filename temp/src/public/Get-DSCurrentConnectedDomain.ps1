function Get-DSCurrentConnectedDomain {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSCurrentConnectedDomain.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

   if ($Script:CurrentDomain -ne $null) {
       return $Script:CurrentDomain
   }
   else {
       try {
           Get-DSDomain -UpdateCurrent
           return $Script:CurrentDomain
       }
       catch {
           Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-ActiveDirectory first."
       }
   }
}

