function Enable-DSObject {
    <#
    .SYNOPSIS
    Sets properties of an AD object
    .DESCRIPTION
    Sets properties of an AD object
    .PARAMETER Identity
    Object to enable. Accepts distinguishedname, GUID, and samAccountName.
    .PARAMETER ComputerName
    Domain controller to use.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .PARAMETER Force
    Force update of the property.
    .EXAMPLE
    Enable-DSObject -Identity 'jdoe'
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium' )]
    param(
        [Parameter(Position = 0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('sAMAccountName', 'distinguishedName')]
        [string]$Identity,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(Position = 3)]
        [Switch]$Force
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'searcher'
            Properties = @('name','adspath','distinguishedname','useraccountcontrol')
        }

        $YesToAll = $false
        $NoToAll = $false
    }
    process {
        $SearcherParams.Identity = $Identity
        $Identities += Get-DSObject @SearcherParams
    }
    end {
        Foreach ($ID in $Identities) {
            $Name = $ID.Properties['name']
            Write-Verbose "$($FunctionName): Start enable object processing for object - $Name"

            if ($ID.properties.Contains('useraccountcontrol')) {
                $UAC = Convert-DSUACProperty -UACProperty ($ID.properties)['useraccountcontrol']
                if ( $UAC -contains 'ACCOUNTDISABLE' ) {
                    Write-Verbose "$($FunctionName): Enabling object name: $Name"
                    if ($pscmdlet.ShouldProcess("Enable $Name?", "Enable $Name?","Enabling $Name")) {
                        if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to enable '$Name'?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                            try {
                                #$ID.Put($Property,$Value)
                                $DE = $ID.GetDirectoryEntry()
                                $DE.psbase.InvokeSet('AccountDisabled', $false)
                                $DE.SetInfo()
                            }
                            catch {
                                Write-Warning "$($FunctionName): Unable to enable $Name!"
                            }
                        }
                    }
                }
                else {
                    Write-Warning "$($FunctionName): $Name is already enabled"
                }
            }
            else {
                Write-Warning "$($FunctionName): $Name is an account object that can not be enabled."
            }
        }
    }
}
