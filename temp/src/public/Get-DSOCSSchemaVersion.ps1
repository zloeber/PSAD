function Get-DSOCSSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSOCSSchemaVersion.md
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
        $ConfigContext = $RootDSE.configurationNamingContext
    }
    
    end {
        # First get the schema version
        if ((Test-DSObjectPath -Path "CN=ms-RTC-SIP-SchemaVersion,$((Get-DSSchema).Name)" @DSParams)) {
            $RangeUpper = (Get-DSObject -SearchRoot "CN=ms-RTC-SIP-SchemaVersion,$((Get-DSSchema).Name)" -Properties 'rangeUpper' -ComputerName $ComputerName -Credential $Credential).rangeUpper

            if (($Script:SchemaVersionTable).Keys -contains $RangeUpper) {
                Write-Verbose "$($FunctionName): OCS/Skype/Lync schema version found."
                $OCSVersion = $Script:SchemaVersionTable[$RangeUpper]
            }
            else {
                Write-Verbose "$($FunctionName): OCS/Skype/Lync schema version not in our list!"
                $OCSVersion = $RangeUpper
            }

            # Config partition lookup, domain naming context
            $OCSDNPSearch = @(Get-DSObject -Filter 'objectclass=msRTCSIP-Service' -SearchRoot $DomNamingContext -SearchScope:SubTree @DSParams)
            if ($OCSDNPSearch.count -ge 1) {
                Write-Verbose "$($FunctionName): Configuration found installed to the system partition"
                New-Object -TypeName psobject -Property @{
                    Version = $OCSVersion
                    Partition = 'System'
                    ConfigPath = ($OCSDNPSearch[0]).adspath
                }
            }

            # Config partition lookup, configuration naming context
            $OCSCPSearch = @(Get-DSObject -Filter 'objectclass=msRTCSIP-Service' -SearchRoot $ConfigContext -SearchScope:SubTree @DSParams)
            if ($OCSCPSearch.count -ge 1) {
                Write-Verbose "$($FunctionName): Configuration found installed to the configuration partition"
                New-Object -TypeName psobject -Property @{
                    Version = $OCSVersion
                    Partition = 'Configuration'
                    ConfigPath = ($OCSCPSearch[0]).adspath
                }
            }
        }
        else {
            Write-Verbose "$($FunctionName): OCS/Skype/Lync not found in schema."
            New-Object -TypeName psobject -Property @{
                Version = 'Not Installed'
                Partition = $null
                ConfigPath = $null
            }
        }
    }
}

