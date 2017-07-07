---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Convert-DSCSE

## SYNOPSIS
Converts a GPO client side extension setting string of GUIDs to readable text.

## SYNTAX

```
Convert-DSCSE [-CSEString] <String>
```

## DESCRIPTION
Converts a GPO client side extension setting string of GUIDs to readable text.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSGPO -Properties * -raw -Limit 1 | foreach {Convert-DSCSE -CSEString $_.gpcuserextensionnames}
```

Retrieve the first GPO with all properties and convert/display the user client side extensions to a readable format.

## PARAMETERS

### -CSEString
String to convert.

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

## NOTES
author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

