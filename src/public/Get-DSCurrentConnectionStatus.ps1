function Get-DSCurrentConnectionStatus {
    <#
    .SYNOPSIS
    Validate if Connect-ActiveDirectory has been run successfully already. Returns True if so.
    .DESCRIPTION
    Validate if Connect-ActiveDirectory has been run successfully already. Returns True if so.
    .EXAMPLE
    PS> Get-DSCurrentConnectionStatus
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    Author: Zachary Loeber
   #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

   if (($Script:CurrentDomain -ne $null) -and ($Script:CurrentForest -ne $null)) {
       return $True
   }
   else {
       return $False
   }
}
