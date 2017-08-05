---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSDirectoryContext

## SYNOPSIS
Get a DirectoryContext object for a specified context.

## SYNTAX

```
Get-DSDirectoryContext [[-ComputerName] <String>] [[-Credential] <PSCredential>] [[-ContextType] <String>]
 [[-ContextName] <String>]
```

## DESCRIPTION
Get a DirectoryContext object for a specified context.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

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
Alternate credentials for retrieving forest information.

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

### -ContextType
Type of DirectoryContext to create.
Can be ApplicationPartition ,ConfigurationSet, DirectoryServer, Domain, or Forest.
Defaults to Domain.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Type, Context

Required: False
Position: 3
Default value: Domain
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ContextName
Can be a forest, domain, or server name (depending on the context type)

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Domain, Forest, DomainName, ForestName

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.DirectoryService.DirectoryContext

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

