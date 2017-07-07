function Test-DSObjectPath {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Test-DSObjectPath.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
    }
    
    Process { }
    end {
        Write-Verbose "$($FunctionName): Validating the following path exists: $Path"

        switch ( $ADConnectState ) {
            { @('AltUserAndServer', 'CurrentUserAltServer', 'AltUser') -contains $_ } {
                Write-Verbose "$($FunctionName): Alternate user and/or server."
                if ($Path.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -DistinguishedName $Path -Credential $Credential

                } 
                else {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -Credential $Credential
                }
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ($Path.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -DistinguishedName $Path
                }
                else {
                    $domObj = Get-DSDirectoryEntry
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }

        if ($domObj.Path -eq $null) {
            return $false
        }
        else {
            return $true
        }
    }
}

