function Convert-DSCSE {
    <#
    .SYNOPSIS
        Converts a GPO client side extension setting string of GUIDs to readable text.
    .DESCRIPTION
        Converts a GPO client side extension setting string of GUIDs to readable text.
    .PARAMETER CSEString
        String to convert.
    .EXAMPLE
        PS> Get-DSGPO -Properties * -raw -Limit 1 | foreach {Convert-DSCSE -CSEString $_.gpcuserextensionnames}

        Retrieve the first GPO with all properties and convert/display the user client side extensions to a readable format.
    .LINK
    https://github.com/zloeber/PSAD
    .NOTES
    author: Zachary Loeber
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$CSEString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    $CSEString = $CSEString -replace '}{','},{'
    ($Script:GPOGuidRef).keys | Foreach-Object {
        $CSEString = $CSEString -replace $_,$GPOGuidRef[$_]
    }

    $CSEString
}
