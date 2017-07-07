function Set-DSObject {
    <#
    .SYNOPSIS
        Sets properties of an AD object
    .DESCRIPTION
        Sets properties of an AD object
    .PARAMETER Identity
        Object to update. Accepts DN, GUID, and name formats.
    .PARAMETER ComputerName
        Domain controller to use.
    .PARAMETER Credential
        Credentials to use for connection to AD.
    .PARAMETER Property
        Property to update.
    .PARAMETER Properties
        A hash of properties to update.
    .PARAMETER Value
        Value to set the property to.
    .PARAMETER Force
        Force update of the property.
    .EXAMPLE
        TBD
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium', DefaultParameterSetName = 'Default' )]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='Default')]
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='MultiProperty')]
        [Alias('Name')]
        [string[]]$Identity,

        [Parameter(Position = 1, ParameterSetName='Default')]
        [Parameter(Position = 1, ParameterSetName='MultiProperty')]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2, ParameterSetName='Default')]
        [Parameter(Position = 2, ParameterSetName='MultiProperty')]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(Position = 3, ParameterSetName='MultiProperty')]
        [hashtable]$Properties,

        [Parameter(Position = 3, ParameterSetName='Default')]
        [string]$Property,

        [Parameter(Position = 4, ParameterSetName='Default')]
        [string]$Value,

        [Parameter(Position = 5, ParameterSetName='Default')]
        [Parameter(Position = 5, ParameterSetName='MultiProperty')]
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
            ReturnDirectoryEntry = $True
            ChangeLogicOrder = $True
            Properties = @('name','adspath','distinguishedname')
        }

        $YesToAll = $false
        $NoToAll = $false
    }

    process {
        $Identities += $Identity
    }
    end {
        Foreach ($ID in $Identities) {
            $SearcherParams.Filter = @("distinguishedName=$ID","objectGUID=$ID","name=$ID","cn=$ID","samaccountname=$ID")
            Get-DSObject @SearcherParams | ForEach-Object {
                $Name = $_.Name
                $DE = $_

                switch ($PsCmdlet.ParameterSetName) {
                    'Default'  {
                        if (($DE | Get-Member -MemberType 'Property').Name -contains $Property) {
                            $CurrentValue = $DE.$Property
                        }
                        else {
                            $CurrentValue = 'null'
                        }
                        Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                        if ($pscmdlet.ShouldProcess("Update AD Object $Name property = '$Property', value = '$Value' (Existing value is '$CurrentValue')", "Update AD Object $Name property = '$Property', value = '$Value' (Existing value is '$CurrentValue')","Updating AD Object $Name property $Property")) {
                            if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to Update '$Name' property $Property (Existing value is '$CurrentValue') with the value of $Value ?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                                try {
                                    $DE.psbase.InvokeSet($Property,$Value)
                                    $DE.SetInfo()
                                }
                                catch {
                                    Write-Warning "$($FunctionName): Unable to update $Name property $Property with $Value"
                                }
                            }
                        }
                    }
                    'MultiProperty'  {
                        $Properties.Keys | ForEach-Object {
                            try {
                                $DE.psbase.InvokeSet($_,$Properties[$_])
                            }
                            catch {
                                Write-Warning "$($FunctionName): Unable to update $Name property $($_)"
                            }
                        }
                        if ($pscmdlet.ShouldProcess("Update AD Object $Name", "Update AD Object $Name?","Updating AD Object $Name")) {
                            if ($Force -or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to Update '$Name'?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                                try {
                                    $DE.SetInfo()
                                }
                                catch {
                                    Write-Warning "$($FunctionName): Unable to update $Name"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
