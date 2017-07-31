---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSForestFunctionalLevel

## SYNOPSIS
Retrieves the current connected forest functional level.

## SYNTAX

```
Get-DSForestFunctionalLevel [[-ComputerName] <String>] [-Credential <PSCredential>]
```

## DESCRIPTION
Retrieves the current connected forest functional level.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSADForestFunctionalLevel
```

Retrieves the current connected forest functional level.

## PARAMETERS

### -ComputerName
Domain controller to use for this search.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: 1
Default value: $Script:CurrentServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to connect with.

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

## INPUTS

## OUTPUTS

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

