---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSUser

## SYNOPSIS
Get Account objects in a given directory service.

## SYNTAX

```
Get-DSUser [[-Identity] <String>] [-ComputerName <String>] [-Credential <PSCredential>] [-Limit <Int32>]
 [-SearchRoot <String>] [-Filter <String[]>] [-Properties <String[]>] [-PageSize <Int32>]
 [-SearchScope <String>] [-SecurityMask <String>] [-TombStone] [-DontJoinAttributeValues]
 [-IncludeAllProperties] [-ChangeLogicOrder] [-Raw] [-ExpandUAC] [-DotNotAllowDelegation] [-AllowDelegation]
 [-UnconstrainedDelegation] [-ModifiedAfter <DateTime>] [-ModifiedBefore <DateTime>] [-CreatedAfter <DateTime>]
 [-CreatedBefore <DateTime>] [-LogOnAfter <DateTime>] [-LogOnBefore <DateTime>] [-NoPasswordRequired]
 [-PasswordNeverExpires] [-Disabled] [-Enabled] [-AdminCount] [-ServiceAccount] [-MustChangePassword] [-Locked]
```

## DESCRIPTION
Get Account objects in a given directory service.
This is just a fancy wrapper for get-dsobject.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSUser -Filter '!(userAccountControl:1.2.840.113556.1.4.803:=2)' -PasswordNeverExpires
```

Retrieves all users that are enabled and have passwords that never expire.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-DSUser -Filter '!(userAccountControl:1.2.840.113556.1.4.803:=2)' -PasswordNeverExpires -ExpandUAC -Properties *
```

Same as above but including all user properties and UAC property expansion

### -------------------------- EXAMPLE 3 --------------------------
```
Get-DSUser -Filter '!(userAccountControl:1.2.840.113556.1.4.803:=2)' -PasswordNeverExpires -ExpandUAC -Properties 'Name','Useraccountcontrol'
```

Same as above but with a reduced number of properties (which VASTLY speeds up results)

## PARAMETERS

### -Identity
Account name to search for.

```yaml
Type: String
Parameter Sets: (All)
Aliases: User, Name

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### -ComputerName
Domain controller to use for this search.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
Default value: $Script:CurrentServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use for connection to AD.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Creds

Required: False
Position: Named
Default value: $Script:CurrentCredential
Accept pipeline input: False
Accept wildcard characters: False
```

### -Limit
Limits items retrieved.
If set to 0 then there is no limit.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: SizeLimit

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchRoot
Root of search.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
LDAP filter for searches.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Properties
Properties to include in output.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: @('Name','ADSPath')
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Items returned per page.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: $Script:PageSize
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchScope
Scope of a search as either a base, one-level, or subtree search, default is subtree.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: Subtree
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecurityMask
Specifies the available options for examining security information of a directory object.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TombStone
Whether the search should also return deleted objects that match the search filter.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DontJoinAttributeValues
Output will automatically join the attributes unless this switch is set.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeAllProperties
Include all optional properties as defined in the schema (with or without values).
This overrides the Properties parameter and can be extremely verbose.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChangeLogicOrder
Alter LDAP filter logic to use OR instead of AND

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Skip attempts to convert known property types.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpandUAC
Expands the UAC attribute into readable format.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DotNotAllowDelegation
Account cannot be delegated

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowDelegation
Search for accounts that can have their credentials delegated

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UnconstrainedDelegation
Account is set for unconstrained delegation

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModifiedAfter
Account was modified after this time

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModifiedBefore
Account was modified before this time

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedAfter
Account was created after this time

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedBefore
Account was created before this time

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogOnAfter
Account was logged on after this time

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogOnBefore
Account was logged on before this time

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoPasswordRequired
Account has no password required set

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordNeverExpires
Account has a never expiring password

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Disabled
Account is disabled

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Enabled
Account is enabled

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdminCount
AdminCount is 1 or greater

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceAccount
Account is a service account

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MustChangePassword
Account must change password

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Locked
Account is locked

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

