function Convert-SidToName {
<#
.SYNOPSIS
Converts a security identifier (SID) to a group/user name.

.DESCRIPTION
Converts a security identifier (SID) to a group/user name.

.PARAMETER SID
The SID to convert.

.EXAMPLE
PS C:\> Convert-SidToName S-1-5-21-2620891829-2411261497-1773853088-1105
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        [ValidatePattern('^S-1-.*')]
        $SID
    )

    try {
        $SID2 = $SID.trim('*')

        # try to resolve any built-in SIDs first
        #   from https://support.microsoft.com/en-us/kb/243330
        Switch ($SID2) {
            'S-1-0'         { 'Null Authority' }
            'S-1-0-0'       { 'Nobody' }
            'S-1-1'         { 'World Authority' }
            'S-1-1-0'       { 'Everyone' }
            'S-1-2'         { 'Local Authority' }
            'S-1-2-0'       { 'Local' }
            'S-1-2-1'       { 'Console Logon ' }
            'S-1-3'         { 'Creator Authority' }
            'S-1-3-0'       { 'Creator Owner' }
            'S-1-3-1'       { 'Creator Group' }
            'S-1-3-2'       { 'Creator Owner Server' }
            'S-1-3-3'       { 'Creator Group Server' }
            'S-1-3-4'       { 'Owner Rights' }
            'S-1-4'         { 'Non-unique Authority' }
            'S-1-5'         { 'NT Authority' }
            'S-1-5-1'       { 'Dialup' }
            'S-1-5-2'       { 'Network' }
            'S-1-5-3'       { 'Batch' }
            'S-1-5-4'       { 'Interactive' }
            'S-1-5-6'       { 'Service' }
            'S-1-5-7'       { 'Anonymous' }
            'S-1-5-8'       { 'Proxy' }
            'S-1-5-9'       { 'Enterprise Domain Controllers' }
            'S-1-5-10'      { 'Principal Self' }
            'S-1-5-11'      { 'Authenticated Users' }
            'S-1-5-12'      { 'Restricted Code' }
            'S-1-5-13'      { 'Terminal Server Users' }
            'S-1-5-14'      { 'Remote Interactive Logon' }
            'S-1-5-15'      { 'This Organization ' }
            'S-1-5-17'      { 'This Organization ' }
            'S-1-5-18'      { 'Local System' }
            'S-1-5-19'      { 'NT Authority' }
            'S-1-5-20'      { 'NT Authority' }
            'S-1-5-80-0'    { 'All Services ' }
            'S-1-5-32-544'  { 'BUILTIN\Administrators' }
            'S-1-5-32-545'  { 'BUILTIN\Users' }
            'S-1-5-32-546'  { 'BUILTIN\Guests' }
            'S-1-5-32-547'  { 'BUILTIN\Power Users' }
            'S-1-5-32-548'  { 'BUILTIN\Account Operators' }
            'S-1-5-32-549'  { 'BUILTIN\Server Operators' }
            'S-1-5-32-550'  { 'BUILTIN\Print Operators' }
            'S-1-5-32-551'  { 'BUILTIN\Backup Operators' }
            'S-1-5-32-552'  { 'BUILTIN\Replicators' }
            'S-1-5-32-554'  { 'BUILTIN\Pre-Windows 2000 Compatible Access' }
            'S-1-5-32-555'  { 'BUILTIN\Remote Desktop Users' }
            'S-1-5-32-556'  { 'BUILTIN\Network Configuration Operators' }
            'S-1-5-32-557'  { 'BUILTIN\Incoming Forest Trust Builders' }
            'S-1-5-32-558'  { 'BUILTIN\Performance Monitor Users' }
            'S-1-5-32-559'  { 'BUILTIN\Performance Log Users' }
            'S-1-5-32-560'  { 'BUILTIN\Windows Authorization Access Group' }
            'S-1-5-32-561'  { 'BUILTIN\Terminal Server License Servers' }
            'S-1-5-32-562'  { 'BUILTIN\Distributed COM Users' }
            'S-1-5-32-569'  { 'BUILTIN\Cryptographic Operators' }
            'S-1-5-32-573'  { 'BUILTIN\Event Log Readers' }
            'S-1-5-32-574'  { 'BUILTIN\Certificate Service DCOM Access' }
            'S-1-5-32-575'  { 'BUILTIN\RDS Remote Access Servers' }
            'S-1-5-32-576'  { 'BUILTIN\RDS Endpoint Servers' }
            'S-1-5-32-577'  { 'BUILTIN\RDS Management Servers' }
            'S-1-5-32-578'  { 'BUILTIN\Hyper-V Administrators' }
            'S-1-5-32-579'  { 'BUILTIN\Access Control Assistance Operators' }
            'S-1-5-32-580'  { 'BUILTIN\Access Control Assistance Operators' }
            Default { 
                $Obj = (New-Object System.Security.Principal.SecurityIdentifier($SID2))
                $Obj.Translate( [System.Security.Principal.NTAccount]).Value
            }
        }
    }
    catch {
        Write-Verbose "Invalid SID: $SID"
        $SID
    }
}
