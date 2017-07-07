function Get-DSCurrentConnectionStatus {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSCurrentConnectionStatus.md
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

