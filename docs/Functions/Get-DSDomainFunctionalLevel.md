---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSDomainFunctionalLevel

## SYNOPSIS
Retrieves the current connected domain functional level.

## SYNTAX

```
Get-DSDomainFunctionalLevel [[-ComputerName] <String>] [-Credential <PSCredential>]
```

## DESCRIPTION
Retrieves the current connected domain functional level.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSDomainFunctionalLevel
```

Retrieves the current connected domain functional level.

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

