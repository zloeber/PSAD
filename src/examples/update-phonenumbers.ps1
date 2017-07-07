Import-Module PSAD
$Cred = Get-Credential      # put in an admin account that can perform the updates
Connect-DSAD -Credential $Cred
$Users = Import-CSV 'C:\temp\ports.csv'
$Users.Where{$_.PortRequested -ne 'FALSE'} | ForEach-Object {
    $ThisUser = Get-DSUser $_.ID -Properties samaccountname,telephonenumber,name,distinguishedname,mail
    $NewTel =  [long]($_.telephonenumber -replace '[^0-9]')
    $NewNumber = "{0:+1\.###\.###\.####}" -f $NewTel
    Set-DSObject -Identity $ThisUser.distinguishedname -Property telephonenumber -Value $NewNumber
}

$Changes = @()

$Users.Where{$_.PortRequested -ne 'FALSE'} | ForEach-Object {
    $ThisUser = Get-DSUser $_.UserID -Properties samaccountname,telephonenumber,name,distinguishedname,mail
    $NewTel =  [long]($_.telephonenumber -replace '[^0-9]')
    $S4bNumber = "{0:+1##########}" -f $NewTel
    $s4buser = Get-CsOnlineUser $ThisUser.mail
    $Changes += New-Object -TypeName psobject -Property @{
        User = $_.UserID
        OldNumber = $s4buser.LineURI
        NewNumber = $S4bNumber
    }
    
    Set-CsOnlineVoiceUser -Identity $s4buser.Identity -TelephoneNumber $S4bNumber -Whatif
}