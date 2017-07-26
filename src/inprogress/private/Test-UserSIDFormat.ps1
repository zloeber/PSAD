function Test-UserSIDFormat {
    [CmdletBinding()]
    param(
        [parameter(Position=0, Mandatory=$True, HelpMessage='String to validate is in user SID format.')]
        [string]$SID
    )
    $sidregex = "^S-\d-\d+-(\d+-){1,14}\d+$"
    if ($SID -imatch $sidregex ) {
        return $true
    }
    else {
        return $false
    }
}
