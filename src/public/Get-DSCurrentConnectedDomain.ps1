function Get-DSCurrentConnectedDomain {
    <#
    .SYNOPSIS
    Gets the currently connected domain object
    .DESCRIPTION
    Gets the currently connected domain object
    .EXAMPLE
    PS> Get-DSCurrentConnectedDomain
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
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
