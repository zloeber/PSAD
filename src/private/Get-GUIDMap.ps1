function Get-GUIDMap {
    <#
    .SYNOPSIS
    Helper to build a hash table of [GUID] -> resolved names
    .DESCRIPTION
    Helper to build a hash table of [GUID] -> resolved names. Heavily adapted from http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving domain information.
    .PARAMETER Domain
    Domain name to retreive the GUID mapping for.
    .PARAMETER Force
    Force Update the domain GUID mapping
    .EXAMPLE
    NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name','Identity')]
        [string]$Forest = ($Script:CurrentForest).name,

        [Parameter( Position = 1 )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position = 2 )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter( Position = 3 )]
        [switch]$Force
    )

    Begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        if ([string]::IsNullOrEmpty($Forest)) {
            $Forest = (Get-DSdomain).Forest.Name
            Write-Verbose "$($FunctionName): No domain passed, searching $Forest"
        }
    }
    End {
        if ((-not $Script:GUIDMap.ContainsKey($Forest)) -or $Force) {
            $GUIDs = @{'00000000-0000-0000-0000-000000000000' = 'All'}

            $ForestSchemaPath = (Get-DSSchema -ComputerName $ComputerName -ForestName $Forest -Credential $Credential).Name

            Write-Verbose "$($FunctionName): Retreiving all the Schema GUID IDs in the $ForestSchemaPath, This could take quite a while..."
            Get-DSObject -SearchRoot $ForestSchemaPath -Filter '(schemaIDGUID=*)' -ComputerName $ComputerName -Credential $Credential -ResultsAs directoryentry | Foreach {
                $GUIDs[(New-Object Guid (,$_.properties.schemaidguid[0])).Guid] = $_.properties.name[0]
            }

            $RightsPath = $ForestSchemaPath -replace "Schema", "Extended-Rights"
            Write-Verbose "$($FunctionName): Retreiving all the Schema GUID IDs in the $RightsPath, This could take quite a while..."
            Get-DSObject -SearchRoot $RightsPath -Filter 'objectClass=controlAccessRight' -ComputerName $ComputerName -Credential $Credential -ResultsAs directoryentry | Foreach {
                $GUIDs[$_.properties.rightsguid[0].toString()] = $_.properties.name[0]
            }

            $Script:GUIDMap[$Forest] = $GUIDs
        }
        else {
            Write-Verbose "$($FunctionName): $Forest already exists in GUIDMap, skipping."
        }
    }
}
