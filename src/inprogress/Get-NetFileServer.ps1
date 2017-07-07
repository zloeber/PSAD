function Get-NetFileServer {
<#
.SYNOPSIS
Returns a list of all file servers extracted from user homedirectory, scriptpath, and profilepath fields.

.DESCRIPTION
Returns a list of all file servers extracted from user homedirectory, scriptpath, and profilepath fields.

.PARAMETER Domain
The domain to query for user file servers, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER TargetUsers
An array of users to query for file servers.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials for connection to the target domain.

.EXAMPLE
PS C:\> Get-NetFileServer

Returns active file servers.

.EXAMPLE
PS C:\> Get-NetFileServer -Domain testing

Returns active file servers for the 'testing' domain.
#>

    [CmdletBinding()]
    param(
        [String]
        $Domain,

        [String]
        $DomainController,

        [String[]]
        $TargetUsers,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    function SplitPath {
        # short internal helper to split UNC server paths
        param([String]$Path)

        if ($Path -and ($Path.split("\\").Count -ge 3)) {
            $Temp = $Path.split("\\")[2]
            if($Temp -and ($Temp -ne '')) {
                $Temp
            }
        }
    }
    $filter = "(!(userAccountControl:1.2.840.113556.1.4.803:=2))(|(scriptpath=*)(homedirectory=*)(profilepath=*))"
    Get-NetUser -Domain $Domain -DomainController $DomainController -Credential $Credential -PageSize $PageSize -Filter $filter | Where-Object {$_} | Where-Object {
            # filter for any target users
            if($TargetUsers) {
                $TargetUsers -Match $_.samAccountName
            }
            else { $True }
        } | ForEach-Object {
            # split out every potential file server path
            if($_.homedirectory) {
                SplitPath($_.homedirectory)
            }
            if($_.scriptpath) {
                SplitPath($_.scriptpath)
            }
            if($_.profilepath) {
                SplitPath($_.profilepath)
            }

        } | Where-Object {$_} | Sort-Object -Unique
}