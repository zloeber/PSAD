---
external help file: PSAD-help.xml
online version: 
schema: 2.0.0
---

# Get-DSOCSTopology

## SYNOPSIS
Retreives the OCS/Skype/Lync information from active directory.

## SYNTAX

```
Get-DSOCSTopology [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Retreives the OCS/Skype/Lync information from active directory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSOCSTopology
```

Returns the OCS/Skype/Lync version found in the current forest and the partition that the version was found in along with any identifiable servers that were found in AD.

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
TBD

## RELATED LINKS

[TBD]()

