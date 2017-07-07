function Get-DSDirectoryEntry {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSDirectoryEntry.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [Alias('DN')]
        [string]$DistinguishedName,

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
                Write-Verbose "$($FunctionName): Alternate user."
                $fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath, "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password)
            }
            'CurrentUserAltServer' {
                Write-Verbose "$($FunctionName): Current user, alternate server."
                if ($DistinguishedName){
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)/$($DistinguishedName)"
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)"
                }
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath)
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    [adsi]''
                }
                else {
                    [adsi]"$($PathType.ToUpper())://$($DistinguishedName)"
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }
    }
}

