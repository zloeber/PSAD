function Get-DSDirectoryEntry {
    <#
    .SYNOPSIS
    Get a DirectoryEntry object for a specified distinguished name.
    .DESCRIPTION
    Get a DirectoryEntry object for a specified distinguished name.
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving forest information.
    .PARAMETER DistinguishedName
    Distinguished Name of AD object we want to get.
    .PARAMETER PathType
    Either LDAP or GC. Default is LDAP.
    .EXAMPLE
    C:\PS> Get-DSDirectoryEntry -DistinguishedName "CN=Domain Users,CN=Users,DC=acmelabs,DC=com"
    Get Domain Users group object.
    .EXAMPLE
    C:\PS> Get-DSDirectoryEntry -DistinguishedName "<GUID=244dc73c2962a349a90fb7cd8bc88c80>"
    Get Domain Users group object by GUID.
    .EXAMPLE
    C:\PS> Get-DSDirectoryEntry -DistinguishedName "<SID=S-1-5-32-545>"
    Get Users group object by known SID
    .OUTPUTS
    System.DirectoryService.DirectoryEntry
    .NOTES
    Author: Zachary Loeber
    modified from https://github.com/darkoperator/ADAudit/blob/dev

    Will only return directoryentry objects and not [adsi] accelerated directory entry objects.
    All hidden methods can be seen via psbase (ie. ($somede.getDirectoryEntry()).psbase | gm)
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [Alias('DN')]
        [string]$DistinguishedName,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [ValidateSet('LDAP', 'GC')]
        [string]$PathType = 'LDAP'
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Managed DN includes path type. (performing case insensitive starts with check)
        if ($DistinguishedName.StartsWith('LDAP',$true,$null)) {
            $PathType = 'LDAP'
            $DistinguishedName = $DistinguishedName.Split('://')[3]
        }

        if ($DistinguishedName.StartsWith('GC',$true,$null)) {
            $PathType = 'GC'
            $DistinguishedName = $DistinguishedName.Split('://')[3]
        }

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    Process {
        switch ( $ADConnectState ) {
            'AltUserAndServer' {
                Write-Verbose "$($FunctionName): Alternate user and server."
                if ($DistinguishedName){
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)/$($DistinguishedName)"
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)"
                }
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath, "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password)
            }
            'AltUser' {
                Write-Verbose "$($FunctionName): Alternate user = $($SplitCreds.Domain)\$($SplitCreds.UserName)"
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    $fullpath = ''
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                }
                #$fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                Write-Verbose "$($FunctionName): Full path = $fullPath"
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath, "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password)
            }
            'CurrentUserAltServer' {
                Write-Verbose "$($FunctionName): Current user, alternate server."
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)"
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)/$($DistinguishedName)"
                }
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath)
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    New-Object -TypeName System.DirectoryServices.DirectoryEntry
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                    New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath)
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }
    }
}
