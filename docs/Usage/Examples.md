# Examples
Here are some examples of using this module to do useful stuff. You can inspect the ldap filter being constructed after each of these examples with `Get-DSLastLDAPFilter` or, if you want the entire set of ADSI search parameters use `Get-DSLastSearchSetting`

## Example 1 - List users added in the last week
```
get-dsuser -CreatedAfter (get-date).AddDays(-14) -properties name,whencreated
```

## Example 2 - Standardize telephonenumber and mobile properties
This will remove spaces and dashes and replace them with periods. It will also append the numbers with a '+'.

```
# Normalize telephone numbers
import-module psad

# Prompt for a credential with access to update the user properties
$cred = get-credential

# all users with either a mobile or regular phone number
$allusers = get-dsuser -enabled -properties name,mobile,telephonenumber,samaccountname,givenname,sn -IncludeNullProperties | Where {$null -ne ($_.telephonenumber + $_.mobile)} | Select-Object *,@{n='newtele';e={$_.telephonenumber -replace '-','.' -replace ' ','.'}},@{n='newmobile';e={$_.mobile -replace '-','.' -replace ' ','.'}}

# Update telephone numbers (remove spaces and dashes)
$allusers | Where {$_.telephonenumber -ne $_.newtele} | foreach {
    Set-DSObject -Identity $_.samaccountname -Property telephonenumber -Value $_.newtele -Credential $cred
}

# Update telephone numbers (prepend with '+')
$allusers | Where {($null -ne $_.telephonenumber) -and ($_.telephonenumber -notmatch "^\+.*$")} | Select samaccountname,@{n='newtele';e={"+1.$($_.telephonenumber)"}} | ForEach-Object {
    Set-DSObject -Identity $_.samaccountname -Property telephonenumber -Value $_.newtele -Credential $cred
}

# Update mobile numbers (remove spaces and dashes)
$allusers | Where {($_.mobile -ne $_.newmobile) -and ($null -ne $_.mobile)} | foreach {
    Set-DSObject -Identity $_.samaccountname -Property mobile -Value $_.newmobile -Credential $cred
}

# Update mobile numbers (prepend with '+1.')
$allusers | Where {($null -ne $_.mobile) -and ($_.mobile -notmatch "^\+.*$")} | Select samaccountname,@{n='newmobile';e={"+1.$($_.mobile)"}} | ForEach-Object {
    Set-DSObject -Identity $_.samaccountname -Property mobile -Value $_.newmobile -Credential $cred
}
```

## Example 3 - Expanding on example 2, create an xml file for polycom phone provisioning (directory lookup)

```
$XMLOutputFile = '.\000000000000-directory.xml'
$XMLItemTemplate = @'
<item>
    <ln>@@LN@@</ln>
    <fn>@@FN@@</fn>
    <ct>@@CT@@</ct>
    <lb>@@LB@@</lb>
</item>

'@
$XMLTemplate = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<directory>
<item_list>
@@ITEMS@@
</item_list>
</directory>
'@

# Get all accounts with either a mobile or main telephone number
$AllNumbers = get-dsuser -enabled -properties name,mobile,telephonenumber,samaccountname,givenname,sn -IncludeNullProperties | Where {$null -ne ($_.telephonenumber + $_.mobile)}

$Directory = @()
# First the mobile numbers
$AllNumbers | Where {$null -ne $_.mobile} | Foreach {
    $Directory += New-Object psobject -Property @{
        ln = $_.sn
        fn = $_.givenname
        ct = $_.mobile -replace '\.',''
        lb = "$($_.givenname) $($_.sn) (cell)"
    }
}

# Next the office/main telephone numbers
$AllNumbers | Where {$null -ne $_.telephonenumber} | Foreach {
    $Directory += New-Object psobject -Property @{
        ln = $_.sn
        fn = $_.givenname
        ct = $_.telephonenumber -replace '\.',''
        lb = "$($_.givenname) $($_.sn) (office)"
    }
}

$AllXMLItems = ''
$Directory | Foreach {
    $AllXMLItems += $XMLItemTemplate -replace '@@LN@@',$_.ln -replace '@@FN@@',$_.fn -replace '@@CT@@',$_.ct -replace '@@LB@@', $_.lb
}

$XMLTemplate -replace '@@ITEMS@@', $AllXMLItems | Out-file -FilePath $XMLOutputFile -Encoding:utf8
```