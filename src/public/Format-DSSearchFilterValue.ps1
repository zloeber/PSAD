function Format-DSSearchFilterValue {
    <#
    .SYNOPSIS
    Escapes Active Directory special characters from a string.
    
    .DESCRIPTION
    There are special characters in Active Directory queries/searches.  This function escapes them so they aren't treated as AD commands/characters.
    
    .PARAMETER SearchString
    The input string with any Active Directory-sensitive characters escaped.

    .OUTPUTS
    System.String
    
    .LINK
    http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters

    .EXAMPLE
    PS> Format-DSSearchFilterValue -String "I have AD special characters (I think)."

    Returns 

    I have AD special characters \28I think\29.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $SearchString = $SearchString.Replace('\', '\5c')
    $SearchString = $SearchString.Replace('*', '\2a')
    $SearchString = $SearchString.Replace('(', '\28')
    $SearchString = $SearchString.Replace(')', '\29')
    $SearchString = $SearchString.Replace('/', '\2f')
    $SearchString.Replace("`0", '\00')
}
