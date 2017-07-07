function Get-DSExchangeServer {
    <#
    .SYNOPSIS
        Retreives Exchange servers from active directory.
    .DESCRIPTION
        Retreives Exchange servers from active directory.
    .PARAMETER ComputerName
        Domain controller to use for this search.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .EXAMPLE
        PS> Get-DSExchangeServer

        Returns Exchange servers found in the current forest.
    .NOTES
        TBD
    .LINK
        TBD
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
        $Props_ExchServers = @(
            'adspath',
            'Name',
            'msexchserversite',
            'msexchcurrentserverroles',
            'adminDisplayName',
            'whencreated',
            'serialnumber',
            'msexchproductid'
        )

        $ConfigNamingContext = (Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams).configurationNamingContext
        $Path_ExchangeOrg = "LDAP://CN=Microsoft Exchange,CN=Services,$($ConfigNamingContext)"
    }
    
    end {
        if (Test-DSObjectPath -Path $Path_ExchangeOrg @DSParams) {

            $ExchOrgs = @(Get-DSObject -Filter 'objectClass=msExchOrganizationContainer' -SearchRoot $Path_ExchangeOrg -SearchScope:SubTree -Properties $Props_ExchOrgs @DSParams)
            
            ForEach ($ExchOrg in $ExchOrgs) {
                $ExchServers = @(Get-DSObject -Filter 'objectCategory=msExchExchangeServer' -SearchRoot $ExchOrg.distinguishedname  -SearchScope:SubTree -Properties $Props_ExchServers  @DSParams)
                
                # Get all found Exchange server information
                ForEach ($ExchServer in $ExchServers) {
                    $AdminGroup = Get-ADPathName $ExchServer.adspath -GetElement 2 -ValuesOnly
                    $ExchSite =  Get-ADPathName $ExchServer.msexchserversite -GetElement 0 -ValuesOnly
                    $ExchRole = $ExchServer.msexchcurrentserverroles

                    # only have two roles in Exchange 2013 so we process a bit differently
                    if ($ExchServer.serialNumber -like "Version 15*") {
                        switch ($ExchRole) {
                            '54' {
                                $ExchRole = 'MAILBOX'
                            }
                            '16385' {
                                $ExchRole = 'CAS'
                            }
                            '16439' {
                                $ExchRole = 'MAILBOX, CAS'
                            }
                        }
                    }
                    else {
                        if($ExchRole -ne 0) {
                            $ExchRole = [Enum]::Parse('MSExchCurrentServerRolesFlags', $ExchRole)
                        }
                    }
                    New-Object -TypeName PSObject -Property @{
                        Organization = $ExchOrg.Name
                        AdminGroup = $AdminGroup
                        Name = $ExchServer.adminDisplayName
                        Role = $ExchRole
                        Site = $ExchSite
                        Created = $ExchServer.whencreated
                        Serial = $ExchServer.serialnumber
                        ProductID = $ExchServer.msexchproductid
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
