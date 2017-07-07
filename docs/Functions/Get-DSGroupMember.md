---
external help file: PSAD-help.xml
online version: 
schema: 2.0.0
---

# Get-DSGroupMember

## SYNOPSIS
Return all members of a group.

## SYNTAX

```
Get-DSGroupMember [-Identity] <String> [-ComputerName <String>] [-Credential <PSCredential>] [-Limit <Int32>]
 [-SearchRoot <String>] [-Properties <String[]>] [-PageSize <Int32>] [-SearchScope <String>]
 [-SecurityMask <String>] [-TombStone] [-DontJoinAttributeValues] [-IncludeAllProperties] [-Raw] [-Recurse]
```

## DESCRIPTION
Return all members of a group.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -Identity
Name to search for.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Group, GroupName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
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

### -Recurse
Computer was modified after this time

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
TBD

## RELATED LINKS

[TBD]()

