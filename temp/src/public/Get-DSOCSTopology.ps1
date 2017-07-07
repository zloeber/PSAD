﻿function Get-DSOCSTopology {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSOCSTopology.md
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

        $OCSConfig = @(Get-DSOCSSchemaVersion @DSParams)
        if ($OCSConfig[0].ConfigPath -eq $null) {
            Write-Verbose "$($FunctionName): OCS/Lync/Skype not found in environment."
            return
        }
    }
    
    end {
        ForEach ($Config in $OCSConfig) {
            $Version = $Config.Version
            $Partition = $Config.Partition
            $ConfigPath = $Config.ConfigPath

            # All internal servers
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-TrustedServer' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-trustedserverfqdn','Name','cn','adspath' @DSParams) | Sort-Object msrtcsip-trustedserverfqdn | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Server'
                    Role = 'Internal'
                    Name = $_.Name
                    FQDN = $_.'msrtcsip-trustedserverfqdn'
                }
            }

            # All edge servers
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-EdgeProxy' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-edgeproxyfqdn','Name','cn' @DSParams) | Sort-Object msrtcsip-edgeproxyfqdn | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Server'
                    Role = 'Edge'
                    Name = $_.Name
                    FQDN = $_.'msrtcsip-edgeproxyfqdn'
                }
            }

                # All global topology servers
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-GlobalTopologySetting' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-backendserver','Name','cn','adspath' @DSParams) | Sort-Object msrtcsip-backendserver | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Server'
                    Role = 'Topology'
                    Name = $_.Name
                    FQDN = $_.'msrtcsip-backendserver'
                }
            }
            
            # All pools
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-Pool' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-pooldisplayname','dnshostname','cn','adspath' @DSParams) | Sort-Object msrtcsip-pooldisplayname | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Pool'
                    Role = 'Pool'
                    Name = $_.'msrtcsip-pooldisplayname'
                    FQDN = $_.dnshostname
                }
            }
        }
    }
}

