---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Add-DSTranslatedUAC

## SYNOPSIS
Enumerate and add additional properties for a user object for useraccountcontrol.

## SYNTAX

```
Add-DSTranslatedUAC [-Identity] <PSObject>
```

## DESCRIPTION
Enumerate and add additional properties for a user object for useraccountcontrol.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSUser -Enabled -IncludeAllProperties | Add-DSTranslatedUAC
```

## PARAMETERS

### -Identity
User or users to process.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: Account, User, Computer

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
http://support.microsoft.com/kb/305144
http://msdn.microsoft.com/en-us/library/cc245514.aspx

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

