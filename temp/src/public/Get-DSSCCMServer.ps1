function Get-DSSCCMServer {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSSCCMServer.md
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
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $SysManageContext = "CN=System Management,CN=System,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $SysManageContext @DSParams)) {

            $SCCMData = @(Get-DSObject -SearchRoot $SysManageContext @DSParams -Filter 'objectClass=mSSMSManagementPoint' -Properties mSSMSCapabilities,mSSMSMPName,dNSHostName,mSSMSSiteCode,mSSMSVersion,mSSMSDefaultMP,mSSMSDeviceManagementPoint)

            Foreach ($SCCM in $SCCMData) {
                $SCCMxml = [XML]$SCCM.mSSMSCapabilities
                $schemaVersionSCCM = $SCCMxml.ClientOperationalSettings.Version
                if (($Script:SchemaVersionTable).Keys -contains $schemaVersionSCCM) {
                    Write-Verbose "$($FunctionName): SCCM version found."
                    $SCCMVer = $Script:SchemaVersionTable[$schemaVersionSCCM]
                }
                else {
                    Write-Verbose "$($FunctionName): SCCM version not in our list!"
                    $SCCMVer = $schemaVersionSCCM
                }
                New-Object -TypeName psobject -Property @{
                    Version = $SCCMVer
                    MPName = $SCCM.mSSMSMPName
                    FQDN = $SCCM.dNSHostName
                    SiteCode = $SCCM.mSSMSSiteCode
                    SMSVersion = $SCCM.mSSMSVersion
                    DefaultMP = $SCCM.mSSMSDefaultMP
                    DeviceMP = $SCCM.mSSMSDeviceManagementPoint
                }
            }
        }
    }
}

