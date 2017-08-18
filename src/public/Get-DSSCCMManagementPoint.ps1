function Get-DSSCCMManagementPoint {
    <#
    .SYNOPSIS
        Retreives the SCCM AD information
    .DESCRIPTION
        Retreives the SCCM AD information
    .PARAMETER ComputerName
        Domain controller to use for this search.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .EXAMPLE
        PS> Get-DSSCCMManagementPoint

        Returns the SCCM servers and their version found in the current forest
    .NOTES
        Returns servers as defined in AD, they may not be 'live' though.
    .LINK
        https://github.com/zloeber/psad
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
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $SysManageContext = "CN=System Management,CN=System,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $SysManageContext @DSParams)) {

            $SCCMData = @(Get-DSObject -SearchRoot $SysManageContext @DSParams -Filter 'objectClass=mSSMSManagementPoint' -Properties name,mSSMSCapabilities,mSSMSMPName,dNSHostName,mSSMSSiteCode,mSSMSVersion,mSSMSDefaultMP,mSSMSDeviceManagementPoint,whenCreated)

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
                    name = $SCCM.name
                    Version = $SCCMVer
                    mSSMSMPName = $SCCM.mSSMSMPName
                    dNSHostName = $SCCM.dNSHostName
                    mSSMSSiteCode = $SCCM.mSSMSSiteCode
                    mSSMSVersion = $SCCM.mSSMSVersion
                    mSSMSDefaultMP = $SCCM.mSSMSDefaultMP
                    mSSMSDeviceManagementPoint = $SCCM.mSSMSDeviceManagementPoint
                    whenCreated = $SCCM.whenCreated
                }
            }
        }
    }
}
