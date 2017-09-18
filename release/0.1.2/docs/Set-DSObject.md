---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Set-DSObject

## SYNOPSIS
Sets properties of an AD object

## SYNTAX

### Default (Default)
```
Set-DSObject [-Identity <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>]
 [[-Property] <String>] [[-Value] <String>] [-Force] [-WhatIf] [-Confirm]
```

### MultiProperty
```
Set-DSObject [-Identity <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>]
 [[-Properties] <Hashtable>] [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Sets properties of an AD object.
You can set a single property or pass in a hashtable of property/value pairs to be updated.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$PropertiesToSet = @{
```

extensionAttribute10 = 'test'
    extensionAttribute11 = 'test2'
}
Set-DSObject -Identity 'webextest' -Properties $PropertiesToSet -Credential (Get-Credential) -Verbose

## PARAMETERS

### -Identity
Object to update.
Accepts DN, GUID, and name formats.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, distinguishedname

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
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

### -Properties
A hash of properties to update.

```yaml
Type: Hashtable
Parameter Sets: MultiProperty
Aliases: 

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Property
Property to update.

```yaml
Type: String
Parameter Sets: Default
Aliases: 

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
Value to set the property to.

```yaml
Type: String
Parameter Sets: Default
Aliases: 

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Force update of the property without prompting.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 6
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

