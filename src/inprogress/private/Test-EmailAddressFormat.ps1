function Test-EmailAddressFormat {
    [CmdletBinding()]
    param(
        [parameter(Position=0, HelpMessage='String to validate email address format.')]
        [string]$emailaddress
    )
    $emailregex = "[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
    if ($emailaddress -imatch $emailregex ) {
        return $true
    }
    else {
        return $false
    }
}
