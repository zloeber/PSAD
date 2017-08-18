function Get-DSGUIDMap {
<#
.SYNOPSIS
Helper to build a hash table of [GUID] -> resolved names

.DESCRIPTION
Helper to build a hash table of [GUID] -> resolved names

.PARAMETER ComputerName
Domain controller to reflect LDAP queries through.

.PARAMETER Credential
The PageSize to set for the LDAP searcher object.

.EXAMPLE
TBD

.NOTES
Heavily adapted from http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx

.LINK
http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx
#>

    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    $GUIDs = @{'00000000-0000-0000-0000-000000000000' = 'All'}

    $SchemaPath = (Get-DSCurrentConnectedForest).schema.name
    $SchemaSearcher = Get-DSDirectorySearcher -Filter "(schemaIDGUID=*)" -SearchRoot $SchemaPath -Properties * -ComputerName $ComputerName -Credential $Credential
    $SchemaSearcher.FindAll() | Foreach-Object {
        # convert the GUID
        $GUIDs[(New-Object Guid (,$_.properties.schemaidguid[0])).Guid] = $_.properties.name[0]
    }

    $RightsPath = $SchemaPath.replace("Schema","Extended-Rights")
    $RightsSearcher = Get-DSDirectorySearcher -Filter "(objectClass=controlAccessRight)" -SearchRoot $RightsPath  -Properties * -ComputerName $ComputerName -Credential $Credential
    $RightsSearcher.FindAll() | ForEach-Object {
        # convert the GUID
        $GUIDs[$_.properties.rightsguid[0].toString()] = $_.properties.name[0]
    }

    $GUIDs
}
