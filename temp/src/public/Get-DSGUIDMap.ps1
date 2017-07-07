function Get-DSGUIDMap {
<#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSGUIDMap.md
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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

