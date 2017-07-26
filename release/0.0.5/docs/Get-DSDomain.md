---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSDomain

## SYNOPSIS
Retrieve an ADSI domain object.

## SYNTAX

```
Get-DSDomain [[-Identity] <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>] [-UpdateCurrent]
```

## DESCRIPTION
Retrieve an ADSI domain object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSDomain
```

Get information on the current domain the machine is a member of.

## PARAMETERS

### -Identity
Forest name to retreive.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name, Domain, DomainName

Required: False
Position: 1
Default value: ($Script:CurrentDomain).name
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ComputerName
Fully Qualified Name of a remote domain controller to connect to.

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
Alternate credentials for retrieving domain information.

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

### -UpdateCurrent
Updates the module stored currently connected forest object

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

## INPUTS

## OUTPUTS

### System.DirectoryServices.ActiveDirectory.Domain

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

