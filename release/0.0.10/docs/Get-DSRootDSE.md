---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSRootDSE

## SYNOPSIS
Retrieves the RootDSE of a forest.

## SYNTAX

```
Get-DSRootDSE [-DistinguishedName <String>] [-ComputerName <String>] [-Credential <PSCredential>]
 [-PathType <String>]
```

## DESCRIPTION
Retrieves the RootDSE of a forest.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSRootDSE
```

Retrieves the current RootDSE directory entry.

## PARAMETERS

### -ComputerName
Domain controller to connect to for the query.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credential to use for connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Creds

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DistinguishedName
The distinguished name of the directory entry to retrieve.

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -PathType
Query LDAP or Global Catalog (GC), default is LDAP

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

