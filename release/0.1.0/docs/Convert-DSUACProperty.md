---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Convert-DSUACProperty

## SYNOPSIS
Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties

## SYNTAX

```
Convert-DSUACProperty [-UACProperty] <String>
```

## DESCRIPTION
Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties.
More of a helper function.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
(Get-DSUser Administrator -Raw -Properties * ).useraccountcontrol | Convert-DSUACProperty
```

## PARAMETERS

### -UACProperty
User account control data to process.

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
Further information:
    http://support.microsoft.com/kb/305144
    http://msdn.microsoft.com/en-us/library/cc245514.aspx

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

