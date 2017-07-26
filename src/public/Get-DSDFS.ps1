function Get-DSDFS {
    <#
    .SYNOPSIS
        Retreives the DFS AD information
    .DESCRIPTION
        Retreives the DFS AD information
    .PARAMETER ComputerName
        Domain controller to use for this search.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .EXAMPLE
        PS> Get-DSDFS

        Returns the DFS information found in the current forest
    .NOTES
        Returns DFS information as defined in AD which may not align with reality.
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
    $DFSDN = "CN=Dfs-Configuration,CN=System,$DomNamingContext"

    if ((Test-DSObjectPath -Path $DFSDN @DSParams)) {
        # process fTDfs first
        $DFSData = @(Get-DSObject -SearchRoot $DFSDN @DSParams -Filter 'objectClass=fTDfs' -Properties Name,distinguishedName,remoteServerName)
        Foreach ($DFSItem in $DFSData) {
            $DomDFSProps = @{
                objectClass = 'fTDfs'
                distinguishedName = $DFSItem.distinguishedName
                name = $DFSItem.Name
                remoteServerName = $DFSItem.remoteServerName -replace ('\*',"")
            }

            New-Object -TypeName psobject -Property $DomDFSProps
        }

        # process msDFS-NamespaceAnchor next
        $DFSData = @(Get-DSObject -SearchRoot $DFSDN @DSParams -Filter 'objectClass=msDFS-NamespaceAnchor' -Properties  Name,distinguishedName,'msDFS-SchemaMajorVersion',whenCreated)

        Foreach ($DFSItem in $DFSData) {
            $DomDFSProps = @{
                name = $DFSItem.Name
                objectClass = 'msDFS-NamespaceAnchor'
                'msDFS-SchemaMajorVersion' = $DFSItem.'msDFS-SchemaMajorVersion'
                whenCreated = $DFSItem.whenCreated
            }
            $DFSItemMembers = @(Get-DSObject -SearchRoot $DFSItem.distinguishedName @DSParams -Filter 'objectClass=msDFS-Namespacev2' -IncludeAllProperties)

            $DFSItemMembers | ForEach-Object {
                $ItemMemberLinks = @(Get-DSObject -SearchRoot $_.distinguishedName @DSParams -Filter 'objectClass=msDFS-Linkv2' -IncludeAllProperties)
                $_ | Add-Member -MemberType:NoteProperty -Name 'DFSItemLinks' -Value $ItemMemberLinks
            }

            $DomDFSProps.ItemMembers = $DFSItemMembers

            New-Object -TypeName psobject -Property $DomDFSProps
        }
    }
}
