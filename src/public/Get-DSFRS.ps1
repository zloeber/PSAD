function Get-DSFRS {
    <#
    .SYNOPSIS
        Retreives the FRS AD information
    .DESCRIPTION
        Retreives the FRS AD information
    .PARAMETER ComputerName
        Domain controller to use for this search.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .EXAMPLE
        PS> Get-DSFRS

        Returns the FRS information found in the current forest
    .NOTES
        Returns FRS information as defined in AD which may not align with reality.
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
    $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
    $DomNamingContext = $RootDSE.RootDomainNamingContext
    $FRSDN = "CN=File Replication Service,CN=System,$DomNamingContext"

    $FRSReplicaSetProps = @( 'name', 'distinguishedName', 'fRSReplicaSetType', 'fRSFileFilter', 'whenCreated')
    $FRSReplicaSetItemProps = @( 'name', 'distinguishedName', 'frsComputerReference', 'whenCreated')

    if ((Test-DSObjectPath -Path $FRSDN @DSParams)) {

        $FRSReplicaSets = @(Get-DSObject -SearchRoot $FRSDN @DSParams -Filter 'objectClass=nTFRSReplicaSet' -Properties $FRSReplicaSetProps)

        Foreach ($FRSReplicaSet in $FRSReplicaSets) {
            $FRSProps = @{
               FRSReplicaSetName = $FRSReplicaSet.name
               FRSReplicaSetType = $FRSReplicaSet.fRSReplicaSetType
               FRSFileFilter = $FRSReplicaSet.fRSFileFilter
               FRSReplicaWhenCreated = $FRSReplicaSet.whenCreated
            }

            $FRSProps.ReplicaSetItems = @(Get-DSObject -SearchRoot $FRSReplicaSet.distinguishedName @DSParams -Filter 'objectClass=nTFRSMember' -Properties $FRSReplicaSetItemProps)

            New-Object -TypeName psobject -Property $FRSProps
        }
    }
}