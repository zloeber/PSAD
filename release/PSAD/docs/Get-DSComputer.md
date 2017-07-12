---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSComputer

## SYNOPSIS
Get computer objects in a given directory service.

## SYNTAX

```
Get-DSComputer [[-Identity] <String>] [-ComputerName <String>] [-Credential <PSCredential>] [-Limit <Int32>]
 [-SearchRoot <String>] [-Filter <String[]>] [-Properties <String[]>] [-PageSize <Int32>]
 [-SearchScope <String>] [-SecurityMask <String>] [-TombStone] [-DontJoinAttributeValues]
 [-IncludeAllProperties] [-ChangeLogicOrder] [-Raw] [-TrustedForDelegation] [-ModifiedAfter <DateTime>]
 [-ModifiedBefore <DateTime>] [-CreatedAfter <DateTime>] [-CreatedBefore <DateTime>] [-LogOnAfter <DateTime>]
 [-LogOnBefore <DateTime>] [-OperatingSystem <String[]>] [-Disabled] [-Enabled] [-SPN <String[]>]
```

## DESCRIPTION
Get computer objects in a given directory service.
This is just a fancy wrapper for get-dsobject.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSComputer -OperatingSystem "*windows 7*","*Windows 10*"
```

Find all computers in the current domain that are running Windows 7 or Windows 10.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-DSComputer -LogOnBefore (Get-Date).AddMonths(-3)
```

Find all computers that have not logged on to the domain in the last 3 months.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-DSComputer -SPN '*TERMSRV*'
```

Find all computers with a service Principal Name.for TERMSRV.
This machine are offering the Remote Desktop service.

## PARAMETERS

### -Identity
Computer name to search for.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Computer, Name

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

### -TrustedForDelegation
Computer is trusted for delegation

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
Computer was modified after this time

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
Computer was modified before this time

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
Computer was created after this time

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
Computer was created before this time

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
Computer was logged on after this time

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
Computer was logged on before this time

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

### -OperatingSystem
Search for specific Operating Systems

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
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

### -SPN
Search for specific SPNs

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

## INPUTS

## OUTPUTS

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

