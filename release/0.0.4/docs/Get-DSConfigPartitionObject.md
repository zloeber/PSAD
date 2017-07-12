---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSConfigPartitionObject

## SYNOPSIS
A helper function for retreiving a configuration partition object.

## SYNTAX

```
Get-DSConfigPartitionObject [[-ComputerName] <String>] [[-Credential] <PSCredential>] [[-SearchPath] <String>]
 [[-Properties] <String[]>] [[-SearchScope] <String>]
```

## DESCRIPTION
A helper function for retreiving a configuration partition object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSConfigPartitionObject -SearchPath 'CN=ms-Exch-Schema-Version-Pt,CN=Schema' -Properties '*'
```

Returns the exchange version found in the current forest.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-DSConfigPartitionObject -SearchPath 'CN=Certification Authorities,CN=Public Key Services,CN=Services' -SearchScope:OneLevel -Properties 'name'
```

Lists all forest enterprise certificate authorities

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

### -SearchPath
Additional path to retreive (ie.
CN=ms-Exch-Schema-Version-Pt,CN=Schema)

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Properties
Properties to retreive.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: @('Name','ADSPath')
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchScope
Scope of a search as either a base, one-level, or subtree search, default is base.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: Base
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Author: Zachary Loeber

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

