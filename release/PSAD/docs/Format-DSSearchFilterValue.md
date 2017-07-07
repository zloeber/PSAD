---
external help file: PSAD-help.xml
online version: http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters
schema: 2.0.0
---

# Format-DSSearchFilterValue

## SYNOPSIS
Escapes Active Directory special characters from a string.

## SYNTAX

```
Format-DSSearchFilterValue [-SearchString] <String>
```

## DESCRIPTION
There are special characters in Active Directory queries/searches. 
This function escapes them so they aren't treated as AD commands/characters.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Format-DSSearchFilterValue -String "I have AD special characters (I think)."
```

Returns 

I have AD special characters \28I think\29.

## PARAMETERS

### -SearchString
The input string with any Active Directory-sensitive characters escaped.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS

[http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters](http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters)

