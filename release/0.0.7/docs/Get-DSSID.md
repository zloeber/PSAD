---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSSID

## SYNOPSIS
Converts a given user/group name to a security identifier (SID).

## SYNTAX

### Object (Default)
```
Get-DSSID [-Name] <String> [[-Domain] <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

### SID
```
Get-DSSID [-SID] <String> [[-Domain] <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Converts a given user/group name to a security identifier (SID).

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSSID -Name jdoe
```

## PARAMETERS

### -Name
The user/group name to convert, can be 'user' or 'DOMAIN\user' format.

```yaml
Type: String
Parameter Sets: Object
Aliases: Group, User

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SID
Specific domain for the given user account, defaults to the current domain.

```yaml
Type: String
Parameter Sets: SID
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Domain
Specific domain for the given user account, defaults to the current domain.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: ($Script:CurrentDomain).Name
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
Fully Qualified Name of a remote domain controller to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: 3
Default value: $Script:CurrentServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Alternate credentials for retrieving information.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Creds

Required: False
Position: 4
Default value: $Script:CurrentCredential
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

