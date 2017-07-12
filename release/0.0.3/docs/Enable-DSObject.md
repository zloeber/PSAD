---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Enable-DSObject

## SYNOPSIS
Sets properties of an AD object

## SYNTAX

```
Enable-DSObject [[-Identity] <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>] [-Force]
 [-WhatIf] [-Confirm]
```

## DESCRIPTION
Sets properties of an AD object

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Enable-DSObject -Identity 'jdoe'
```

## PARAMETERS

### -Identity
Object to enable.
Accepts distinguishedname, GUID, and samAccountName.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ComputerName
Domain controller to use.

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

### -Force
Force update of the property.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
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
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

