Function Validate-EmailAddress {
    param( 
        [Parameter(Mandatory=$true)]
        [string]$EmailAddress
    )
    try {
        $check = New-Object System.Net.Mail.MailAddress($EmailAddress)
        return $true
    }
    catch {
        return $false
    }
}
