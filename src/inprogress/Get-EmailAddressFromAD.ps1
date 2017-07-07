function Get-EmailAddressFromAD {
    <#
    .SYNOPSIS
    Return the email address of a User ID from AD.
    .DESCRIPTION
    Return the email address of a User ID from AD.
    .PARAMETER UserID
    User ID to search for in AD.
    .EXAMPLE
    PS> Get-EmailAddressFromAD -UserID jdoe

    Reterns the email address for jdoe from the domain.

    .LINK
    http://www.the-little-things.net/

    .LINK
    https://www.github.com/zloeber/EWSModule

    .NOTES
    Author: Zachary Loeber
    Requires: Powershell 3.0
    Version History
    1.0.0 - Initial release
    #>
    [CmdletBinding()]
    param(
        [parameter(Position=0, HelpMessage='ID to lookup. Defaults to current users SID')]
        [string]$UserID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand
    
    if (-not (Test-EmailAddressFormat $UserID)) {
        try {
            if (Test-UserSIDFormat $UserID) {
                $user = [ADSI]"LDAP://<SID=$UserID>"
                $retval = $user.Properties.mail
            }
            else {
                $strFilter = "(&(objectCategory=User)(samAccountName=$($UserID)))"
                $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
                $objSearcher.Filter = $strFilter
                $objPath = $objSearcher.FindOne()
                $objUser = $objPath.GetDirectoryEntry()
                $retval = $objUser.mail
            }
        }
        catch {
            Write-Debug ("$($FunctionName): Full Error - $($_.Exception.Message)")
            throw "$($FunctionName): Cannot get directory information for $UserID"
        }
        if ([string]::IsNullOrEmpty($retval)) {
            Write-Verbose "$($FunctionName): Cannot determine the primary email address for - $UserID"
            throw "$($FunctionName): Autodiscover failure - No email address associated with current user."
        }
        else {
            return $retval
        }
    }
    else {
        return $UserID
    }
}