---
external help file: PSAD-help.xml
online version: 
schema: 2.0.0
---

# Move-DSObject

## SYNOPSIS
Move AD objects to another OU.

## SYNTAX

```
Move-DSObject [-Identity <String[]>] [[-ComputerName] <String>] [[-Credential] <PSCredential>]
 [[-Destination] <String>] [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Move AD objects to another OU.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -Identity
Object to move.
Accepts DN, GUID, and name formats.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ComputerName
Domain controller to use for this move.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: 2
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
Position: 3
Default value: $Script:CurrentCredential
Accept pipeline input: False
Accept wildcard characters: False
```

### -Destination
Desination OU to move objects into.

```yaml
Type: String
Parameter Sets: (All)
Aliases: OU, TargetPath

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force move to OU without confirmation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

