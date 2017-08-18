function Get-DSOCSTopology {
    <#
    .SYNOPSIS
    Retreives the OCS/Skype/Lync information from active directory.
    .DESCRIPTION
    Retreives the OCS/Skype/Lync information from active directory.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .EXAMPLE
    PS> Get-DSOCSTopology

    Returns the OCS/Skype/Lync version found in the current forest and the partition that the version was found in along with any identifiable servers that were found in AD.
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
