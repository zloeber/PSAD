---
external help file: PSAD-help.xml
online version: https://github.com/zloeber/PSAD
schema: 2.0.0
---

# Convert-DSName

## SYNOPSIS
Translates Active Directory names between various formats.

## SYNTAX

```
Convert-DSName [-OutputType] <String> [-Name] <String[]> [-InputType <String>] [-InitType <String>]
 [-InitName <String>] [-ChaseReferrals] [-Credential <PSCredential>]
```

## DESCRIPTION
Translates Active Directory names between various formats using the NameTranslate COM object.
Before names can be translated, the NameTranslate object must first be initialized.
The default initialization type is 'GC' (see the -InitType parameter).
You can use the -Credential parameter to initialize the NameTranslate object using specific credentials.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Convert-DSName -OutputType dn -Name fabrikam\pflynn
```

This command outputs the specified domain\username as a distinguished name.

PS C:\\\> Convert-DSName canonical 'CN=Phineas Flynn,OU=Engineers,DC=fabrikam,DC=com'
This command outputs the specified DN as a canonical name.

PS C:\\\> Convert-DSName dn fabrikam\pflynn -InitType server -InitName dc1
This command uses the server dc1 to translate the specified name.

PS C:\\\> Convert-DSName display fabrikam\pflynn -InitType domain -InitName fabrikam
This command uses the fabrikam domain to translate the specified name.

PS C:\\\> Convert-DSName dn 'fabrikam.com/Engineers/Phineas Flynn' -Credential (Get-Credential)
Prompts for credentials, then uses those credentials to translate the specified name.

PS C:\\\> Get-Content DNs.txt | Convert-DSName -OutputType display -InputType dn
Outputs the display names for each of the distinguished names in the file DNs.txt.

## PARAMETERS

### -OutputType
The output name type, which must be one of the following:
1779              RFC 1779; e.g., 'CN=Phineas Flynn,OU=Engineers,DC=fabrikam,DC=com'
DN                short for 'distinguished name'; same as 1779
canonical         canonical name; e.g., 'fabrikam.com/Engineers/Phineas Flynn'
NT4               domain\username; e.g., 'fabrikam\pflynn'
display           display name
domainSimple      simple domain name format
enterpriseSimple  simple enterprise name format
GUID              GUID; e.g., '{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}'
UPN               user principal name; e.g., 'pflynn@fabrikam.com'
canonicalEx       extended canonical name format
SPN               service principal name format

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name to translate.
This parameter does not support wildcards.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -InputType
The input name type.
Possible values are the same as -OutputType, with the following additions:
unknown          unknown name format; the system will estimate the format
SIDorSIDhistory  SDDL string for the SID or one from the object's SID history
The default value for this parameter is 'unknown'.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: Unknown
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitType
The type of initialization to be performed, which must be one of the following:
domain  Bind to the domain specified by the -InitName parameter
server  Bind to the server specified by the -InitName parameter
GC      Locate and bind to a global catalog
The default value for this parameter is 'GC'.
When -InitType is not 'GC', you must also specify the -InitName parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: GC
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitName
When -InitType is 'domain' or 'server', this parameter specifies which domain or server to bind to.
This parameter is ignored if -InitType is 'GC'.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChaseReferrals
This parameter specifies whether to chase referrals.
(When a server determines that other servers hold relevant data, in part or as a whole, it may refer the client to another server to obtain the result.
Referral chasing is the action taken by a client to contact the referred-to server to continue the directory search.)

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Uses the specified credentials when initializing the NameTranslate object.

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

## INPUTS

## OUTPUTS

## NOTES
Written by Bill Stewart (bstewart@iname.com)
PowerShell wrapper script for the NameTranslate COM object.
http://windowsitpro.com/active-directory/translating-active-directory-object-names-between-formats

## RELATED LINKS

