---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Convert-DSPwdProperty

## SYNOPSIS
Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties

## SYNTAX

```
Convert-DSPwdProperty [-PwdProperties] <String>
```

## DESCRIPTION
Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties.
More of a helper function.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSObject 'dc=contoso,dc=com' -IncludeAllProperties | Convert-DSPwdProperty
```

## PARAMETERS

### -PwdProperties
User account control data to process.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
author: Zachary Loeber
Further information:
https://msdn.microsoft.com/en-us/library/ms679431(v=vs.85).aspx

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

