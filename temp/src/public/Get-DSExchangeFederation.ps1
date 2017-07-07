function Get-DSExchangeFederation {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSExchangeFederation.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        $ExchangeConfig = @(Get-DSExchangeSchemaVersion @DSParams)
        if ($ExchangeConfig -eq $null) {
            # Exchange isn't in the environment
            Write-Verbose "$($FunctionName): No exchange environment found."
            return $null
        }
        $Props_ExchOrgs = @(
            'distinguishedName',
            'Name'
        )
        $Props_ExchFeds = @(
            'Name',
            'msExchFedIsEnabled',
            'msExchFedDomainNames',
            'msExchFedEnabledActions',
            'msExchFedTargetApplicationURI',
            'msExchFedTargetAutodiscoverEPR',
            'msExchVersion'
        )
        $ConfigNamingContext = (Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams).configurationNamingContext
        $Path_ExchangeOrg = "LDAP://CN=Microsoft Exchange,CN=Services,$($ConfigNamingContext)"
        $ExchangeFederations = @()
    }
    
    end {
        if (Test-DSObjectPath -Path $Path_ExchangeOrg @DSParams) {

            $ExchOrgs = @(Get-DSObject -Filter 'objectClass=msExchOrganizationContainer' -SearchRoot $Path_ExchangeOrg -SearchScope:SubTree -Properties $Props_ExchOrgs @DSParams)
            
            ForEach ($ExchOrg in $ExchOrgs) {
                $ExchServers = @(Get-DSObject -Filter 'objectCategory=msExchExchangeServer' -SearchRoot $ExchOrg.distinguishedname  -SearchScope:SubTree -Properties $Props_ExchServers  @DSParams)
                
                # Get all found Exchange federations
                $ExchangeFeds = @(Get-DSObject -Filter 'objectCategory=msExchFedSharingRelationship' -SearchRoot "LDAP://CN=Federation,$([string]$ExchOrg.distinguishedname)"  -SearchScope:SubTree -Properties $Props_ExchFeds)
                Foreach ($ExchFed in $ExchangeFeds) {
                    New-Object -TypeName psobject -Property @{
                        Organization = $ExchOrg.Name
                        Name = $ExchFed.Name
                        Enabled = $ExchFed.msExchFedIsEnabled
                        Domains = @($ExchFed.msExchFedDomainNames)
                        AllowedActions = @($ExchFed.msExchFedEnabledActions)
                        TargetAppURI = $ExchFed.msExchFedTargetApplicationURI
                        TargetAutodiscoverEPR = $ExchFed.msExchFedTargetAutodiscoverEPR
                        ExchangeVersion = $ExchFed.msExchVersion
                    }
                }
            }
        }
        else {
            Write-Warning "$($FunctionName): Exchange found in schema but nothing found in services path - $Path_ExchangeOrg"
            return $null
        }
    }
}

