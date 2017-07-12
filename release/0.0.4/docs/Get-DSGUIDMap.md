---
external help file: PSAD-help.xml
online version: http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx
schema: 2.0.0
---

# Get-DSGUIDMap

## SYNOPSIS
Helper to build a hash table of \[GUID\] -\> resolved names

## SYNTAX

```
Get-DSGUIDMap [[-ComputerName] <String>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
Helper to build a hash table of \[GUID\] -\> resolved names

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
TBD
```

## PARAMETERS

### -ComputerName
Domain controller to reflect LDAP queries through.

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
The PageSize to set for the LDAP searcher object.

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
Heavily adapted from http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx

## RELATED LINKS

[http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx](http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx)

