---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSExchangeFederation

## SYNOPSIS
Retreives Exchange federations from active directory.

## SYNTAX

```
Get-DSExchangeFederation [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Retreives Exchange federations from active directory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSExchangeTopology
```

Returns Exchange federations found in the current forest.

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

