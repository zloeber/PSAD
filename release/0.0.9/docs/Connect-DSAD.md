---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Connect-DSAD

## SYNOPSIS
Connect to active directory.

## SYNTAX

```
Connect-DSAD [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Connect to active directory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$cred = Get-Credential
```

PS\> $a = Connect-ActiveDirectory -Creds $cred -ComputerName 10.10.10.10
PS\> $a.Path = 'LDAP://10.10.10.10/RootDSE'
PS\> $a.namingContexts

Using alternate credentials connect to 10.10.10.10 then browse to the RootDSE and use it to list all the available AD partitions

### -------------------------- EXAMPLE 2 --------------------------
```
$cred = Get-Credential
```

PS\> $a = Connect-ActiveDirectory -Creds $cred -ComputerName 10.10.10.10
PS\> $a.Path = 'LDAP://10.10.10.10/RootDSE'
PS\> $Script:CurrentDomains = Connect-ActiveDirectory -ADContextType:Domain -Creds $cred -Computer 10.10.10.10
PS\> $DCs = $Script:CurrentDomains.DomainControllers
PS\> ForEach($partition in ($a.namingContexts)) {
PS\>     Write-Host -ForegroundColor:Magenta "Partition: $($partition)"
PS\>     Foreach ($DC in $DCs) {
PS\>         $Script:CurrentDomainControllerMetadata = $DC.GetReplicationMetadata($partition)
PS\>         $dsaSignature = $Script:CurrentDomainControllerMetadata.Item("dsaSignature") 
PS\>         Write-Host -ForegroundColor:DarkMagenta "    Server = $($DC) --- Backed up $($dsaSignature.LastOriginatingChangeTime.DateTime)\`n"
PS\>     }
PS\> }

Using alternate credentials connect to 10.10.10.10 then enumerate the partitions in the domain as well as the DCs.
Then generate a report of the last backup
time being reported on each DC for each partition.

## PARAMETERS

### -ComputerName
A remote domain controller to attempt to bind to for this connection.
If not defined then the current joined domain will be used with the closest domain controller found.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Alternate credentials to use for the connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: Creds

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

