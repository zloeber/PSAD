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
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $ConfigNamingContext = $rootDSE.configurationNamingContext
        $Path_ExchangeOrg = "LDAP://CN=Microsoft Exchange,CN=Services,$($ConfigNamingContext)"

        if (-not (Test-DSObjectPath -Path $Path_ExchangeOrg @DSParams)) {
            # Exchange isn't in the environment
            Write-Verbose "$($FunctionName): No exchange environment found in $Path_ExchangeOrg."
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
    }

    end {
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
                $ServerVersion = $ExchServer.serialnumber
                if ($ExchServer.serialnumber -match '^Version\s(.*)\s\(.*$') {
                    $ThisServerVersion = $Matches[1]
                    if ($ExchangeServerVersions.ContainsKey($ThisServerVersion)) {
                        $ServerVersion = $ExchangeServerVersions.($ThisServerVersion)
                    }
                }
                New-Object -TypeName PSObject -Property @{
                    Organization = $ExchOrg.Name
                    AdminGroup = $AdminGroup
                    Name = $ExchServer.adminDisplayName
                    Version = $ServerVersion
                    Role = $ExchRole
                    Site = $ExchSite
                    Created = $ExchServer.whencreated
                    Serial = $ExchServer.serialnumber
                    ProductID = $ExchServer.msexchproductid
                }
            }
        }
    }
}