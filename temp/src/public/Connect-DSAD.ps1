function Connect-DSAD {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Connect-DSAD.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName,
        
        [parameter(Position=1)]
        [alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    # Update the module variables
    $Script:CurrentDomain = $null
    $Script:CurrentForest = $null
    $Script:CurrentBaseDN = $null
    $Script:CurrentCredential = $Credential
    $Script:CurrentServer = $ComputerName

    $CurrCreds = Split-Credential -Credential $Credential
    
    Write-Verbose "$($FunctionName): Using Domain = $($CurrCreds.Domain); UserName = $($CurrCreds.UserName)"

    switch ((Get-CredentialState -Credential $Credential -ComputerName $ComputerName) ) {
        'AltUserAndServer' {
            # When connecting with alternate credentials we first connect to the AD and Directory contexts to then get our forest and domain objects setup
            Write-Verbose "$($FunctionName): Attempting to connect with alternate credentials to $ComputerName"
            $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext 'DirectoryServer', $ComputerName, $CurrCreds.UserName, $CurrCreds.Password
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        'AltUser' {
            # When connecting with alternate credentials without a server name we first try to locate an acceptable DC as connecting to a DC can expose both domain and forest info
            Write-Verbose "$($FunctionName): Attempting to connect with alternate credentials by first locating a DC to connect to."
            $DCContext = Get-DSDirectoryContext -Credential $Credential -ContextType 'Domain' -ContextName $CurrCreds.Domain
            $ComputerName = ([System.DirectoryServices.ActiveDirectory.DomainController]::findOne($DCContext)).Name
            $Script:CurrentServer = $ComputerName
            
            Write-Verbose "$($FunctionName): Connecting to $ComputerName"
            $ADContext = Get-DSDirectoryContext -Credential $Credential -ContextType 'DirectoryServer' -ContextName $ComputerName
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        'CurrentUserAltServer' {
            # We are using the current user but connecting to a different server
            Write-Verbose "$($FunctionName): Attempting to connect with current credentials to $ComputerName"
            $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext 'DirectoryServer', $ComputerName
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        'CurrentUser' {
            # Using current credentials we first gather the current forest and domain information and then create the contexts
            Write-Verbose "$($FunctionName): Attempting to connect as the current user to the current domain"
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        Default {
            Write-Error "$($FunctionName): Unable to connect to AD!"
        }
    }
}

