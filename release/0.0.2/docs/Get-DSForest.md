---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSForest

## SYNOPSIS
Retrieve an ADSI forest object.

## SYNTAX

```
Get-DSForest [[-Identity] <String>] [-ComputerName <String>] [-Credential <PSCredential>] [-UpdateCurrent]
```

## DESCRIPTION
Retrieve an ADSI forest object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSForest
```

Gets the forest for the domain the host is corrently joined to or that was previously connected to via Connect-DSAD.

## PARAMETERS

### -Identity
Forest name to retreive.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Forest, ForestName

Required: False
Position: 1
Default value: ($Script:CurrentForest).name
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### -ComputerName
Fully Qualified Name of a remote domain controller to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
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
Position: Named
Default value: $Script:CurrentCredential
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateCurrent
Updates the module stored currently connected forest object

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

### System.DirectoryServices.ActiveDirectory.Forest

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

