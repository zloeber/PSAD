---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Get-DSDirectoryEntry

## SYNOPSIS
Get a DirectoryEntry object for a specified distinguished name.

## SYNTAX

```
Get-DSDirectoryEntry [[-DistinguishedName] <String>] [-ComputerName <String>] [-Credential <PSCredential>]
 [-PathType <String>]
```

## DESCRIPTION
Get a DirectoryEntry object for a specified distinguished name.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-DSDirectoryEntry -DistinguishedName "CN=Domain Users,CN=Users,DC=acmelabs,DC=com"
```

Get Domain Users group object.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-DSDirectoryEntry -DistinguishedName "<GUID=244dc73c2962a349a90fb7cd8bc88c80>"
```

Get Domain Users group object by GUID.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-DSDirectoryEntry -DistinguishedName "<SID=S-1-5-32-545>"
```

Get Users group object by known SID

## PARAMETERS

### -DistinguishedName
Distinguished Name of AD object we want to get.

```yaml
Type: String
Parameter Sets: (All)
Aliases: DN

Required: False
Position: 1
Default value: None
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

### -PathType
Either LDAP or GC.
Default is LDAP.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: LDAP
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.DirectoryService.DirectoryEntry

## NOTES
Author: Zachary Loeber
modified from https://github.com/darkoperator/ADAudit/blob/dev

Will only return directoryentry objects and not \[adsi\] accelerated directory entry objects.
All hidden methods can be seen via psbase (ie.
($somede.getDirectoryEntry()).psbase | gm)

## RELATED LINKS

[https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

