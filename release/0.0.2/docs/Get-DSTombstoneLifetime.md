---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSTombstoneLifetime

## SYNOPSIS
Retreives the forest tombstone lifetime in days.

## SYNTAX

```
Get-DSTombstoneLifetime [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Retreives the forest tombstone lifetime in days.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSTombstoneLifetime
```

Returns the tombstone lifetime period for the current forest

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
Credentials to use for connection to AD.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Creds

Required: False
Position: 2
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

