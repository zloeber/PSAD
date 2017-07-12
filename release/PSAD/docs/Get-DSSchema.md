---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSSchema

## SYNOPSIS
Get information of the schema for the existing forest.

## SYNTAX

```
Get-DSSchema [[-ComputerName] <String>] [[-Credential] <PSCredential>] [[-ForestName] <String>]
 [-UpdateCurrent]
```

## DESCRIPTION
Get information of the schema for the existing forest.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSSchema
```

Get information on the current schema for the forest currently connected to.

## PARAMETERS

### -ComputerName
Fully Qualified Name of a remote domain controller to connect to.

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
Alternate credentials for retrieving information.

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

### -ForestName
Forest to retrieve.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Forest

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateCurrent
Update the currently stored connected schema information within the module.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

