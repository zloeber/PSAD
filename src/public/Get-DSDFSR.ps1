function Get-DSDFSR {
    <#
    .SYNOPSIS
    Retreives the DFSR AD information
    .DESCRIPTION
    Retreives the DFSR AD information
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .EXAMPLE
    PS> Get-DSDFSR

    Returns the DFSR information found in the current forest
    .NOTES
    Returns DFSR information as defined in AD which may not align with reality.
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
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $DSParams = @{
        ComputerName = $ComputerName
        Credential = $Credential
    }
    $DFSGroupTopologyProps = @( 'Name', 'distinguishedName', 'msDFSR-ComputerReference')

    $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
    $DomNamingContext = $RootDSE.RootDomainNamingContext
    $DFSRDN = "CN=DFSR-GlobalSettings,CN=System,$DomNamingContext"

    if ((Test-DSObjectPath -Path $DFSRDN @DSParams)) {
        $DFSRGroups = @(Get-DSObject -SearchRoot $DFSRDN @DSParams -Filter 'objectClass=msDFSR-ReplicationGroup' -Properties 'Name','distinguishedName')
        Foreach ($DFSRGroup in $DFSRGroups) {
            $DFSRGC = @()
            $DFSRGTop = @()
            $DFSRGroupContentDN = "CN=Content,$($DFSRGroup.distinguishedName)"
            $DFSRGroupTopologyDN = "CN=Topology,$($DFSRGroup.distinguishedName)"

            $DFSRGroupContent = @(Get-DSObject -SearchRoot $DFSRGroupContentDN @DSParams -Filter 'objectClass=msDFSR-ContentSet' -Properties 'Name')
            $DFSRGC = @($DFSRGroupContent | ForEach-Object {$_.Name})

            $DFSRGroupTopology = @(Get-DSObject -SearchRoot $DFSRGroupTopologyDN @DSParams -Filter 'objectClass=msDFSR-Member' -Properties $DFSGroupTopologyProps)

            foreach ($DFSRGroupTopologyItem in $DFSRGroupTopology) {
                $DFSRServerName = Get-ADPathName $DFSRGroupTopologyItem.'msDFSR-ComputerReference' -GetElement 0 -ValuesOnly
                $DFSRGTop += [string]$DFSRServerName
            }
            $DomDFSRProps = @{
                Name = $DFSRGroup.Name
                Content = $DFSRGC
                RemoteServerName = $DFSRGTop
            }

            New-Object -TypeName psobject -Property $DomDFSRProps
        }
    }
}