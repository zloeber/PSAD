---
external help file: PSAD-help.xml
online version: 
schema: 2.0.0
---

# Get-DSOCSSchemaVersion

## SYNOPSIS
Retreives the OCS/Skype/Lync schema version and configuraiton partition location from active directory.

## SYNTAX

```
Get-DSOCSSchemaVersion [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Retreives the OCS/Skype/Lync schema version and configuraiton partition location from active directory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSOCSSchemaVersion
```

Returns the OCS/Skype/Lync version found in the current forest and the partition that the version was found in.

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

