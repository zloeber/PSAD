---
external help file: PSAD-help.xml
online version: https://www.the-little-things.net
schema: 2.0.0
---

# Get-CredentialState

## SYNOPSIS
Returns the type of connection you have based on what is passed.

## SYNTAX

```
Get-CredentialState [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Returns the type of connection you have based on what is passed.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Credential $null
```

Returns the current user settings.
Password will be returned as $null.

## PARAMETERS

### -ComputerName
Fully Qualified Name of a remote domain controller to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: $Script:CurrentServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
The credential to enumerate.

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

[https://www.the-little-things.net](https://www.the-little-things.net)

