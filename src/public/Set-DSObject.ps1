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
    Force update of the property without prompting.
    .EXAMPLE
    $PropertiesToSet = @{
        extensionAttribute10 = 'test'
        extensionAttribute11 = 'test2'
    }
    Set-DSObject -Identity 'webextest' -Properties $PropertiesToSet -Credential (Get-Credential) -Verbose
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium', DefaultParameterSetName = 'Default' )]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='Default')]
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='MultiProperty')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name')]
        [string]$Identity,

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

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $GenericProperties = @('name','adspath','distinguishedname')
        $Identities = @()
        $YesToAll = $false
        $NoToAll = $false

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'searcher'
        }

        switch ($PsCmdlet.ParameterSetName) {
            'Default'  {
                $SearcherParams.Properties = ($GenericProperties + $Property) | Select-Object -Unique
            }
            'MultiProperty' {
                $SearcherParams.Properties = ($GenericProperties + $Properties.Keys) | Select-Object -Unique
            }
        }
        Write-Verbose "$($FunctionName): Properties for this search include $($SearcherParams.Properties -join ', ')"
    }
    process {
        $SearcherParams.Identity = $Identity
        $Identities += Get-DSObject @SearcherParams
    }
    end {
        Foreach ($ID in $Identities) {
            $Name = $ID.Properties['name']
            $DE = $ID.GetDirectoryEntry()

            Write-Verbose "$($FunctionName): Start processing for object - $Name"
            switch ($PsCmdlet.ParameterSetName) {
                'Default'  {
                    Write-Verbose "$($FunctionName): Setting a single property"
                    if (($DE | Get-Member -MemberType 'Property').Name -contains $Property) {
                        $CurrentValue = $DE.$Property
                    }
                    else {
                        $CurrentValue = '<empty>'
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
                    Write-Verbose "$($FunctionName): Setting multiple properties"
                    Foreach ($Prop in ($Properties.Keys)) {
                        try {
                            Write-Verbose "$($FunctionName): Setting $Prop to be $($Properties[$Prop])"
                            $DE.psbase.InvokeSet($Prop,$Properties[$Prop])
                        }
                        catch {
                            Write-Warning "$($FunctionName): Unable to update $Name property named: $Prop"
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
