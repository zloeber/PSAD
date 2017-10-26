---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSDomainPasswordPolicy

## SYNOPSIS
Retrieves default password policy for given domain.

## SYNTAX

```
Get-DSDomainPasswordPolicy [[-Identity] <String>] [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Retrieves default password policy for given domain.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSDomainPasswordPolicy
```

ComplexityEnabled           : True
DistinguishedName           : DC=contoso,DC=com
LockoutDuration             : 00:15:00
LockoutObservationWindow    : 00:14:00
LockoutThreshold            : 6
MaxPasswordAge              : 90.00:00:00
MinPasswordAge              : 7.00:00:00
MinPasswordLength           : 8
PasswordHistoryCount        : 24
ReversibleEncryptionEnabled : False

## PARAMETERS

### -Identity
Domain name to retreive.

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

## INPUTS

## OUTPUTS

### Object

## NOTES
Author: Zachary Loeber
This does not account for any GPO driven default domain password policies.

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

