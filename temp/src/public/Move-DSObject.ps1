function Move-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Move-DSObject.md
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium' )]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name')]
        [string[]]$Identity,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(Position = 3)]
        [Alias('OU','TargetPath')]
        [string]$Destination,
        
        [Parameter(Position = 4, HelpMessage = 'Force move to OU without confirmation.')]
        [Switch]$Force
    )
    
    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        # If the destination OU doesn't exist then there is nothing for us to do...
        if (-not (Test-DSObjectPath -Path $Destination @SearcherParams)) {
            Write-Error "$($FunctionName): Destination OU doesn't seem to exist: $Destination"
            return
        }
        Else {
            Write-Verbose "$($FunctionName): Retreiving DN of the OU at $Destination"
            $OU = Get-DSDirectoryEntry @SearcherParams -DistinguishedName $Destination
        }

        $SearcherParams.ReturnDirectoryEntry = $True
        $SearcherParams.ChangeLogicOrder = $True
        $YesToAll = $false
        $NoToAll = $false
    }
    
    Process {
        $Identities += $Identity
    }
    end {
        Foreach ($ID in $Identities) {
            $SearcherParams.Filter = @("distinguishedName=$ID","objectGUID=$ID","name=$ID","cn=$ID")
            Get-DSObject @SearcherParams | ForEach-Object {
                $Name = $_.Properties['name']
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Move AD Object $Name to $Destination", "Move AD Object $Name to $Destination?","Moving AD Object $Name")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to move '$Name'?", "Moving AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            ($_.GetDirectoryEntry()).MoveTo($OU)
                        }
                        catch {
                            throw $_
                        }
                    }
                }
            }
        }
    }
}

