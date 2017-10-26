function New-DSObject {
    <#
    .SYNOPSIS
    Creates a new object in AD.
    .DESCRIPTION
    Creates a new object in AD.
    .PARAMETER Identity
    Name of object to create.
    .PARAMETER Path
    Path to create the object within.
    .PARAMETER ObjectType
    The type of object to create.
    .PARAMETER ComputerName
    Domain controller to use.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .PARAMETER OtherAttributes
    Hashtable of attributes to apply to the object.
    .EXAMPLE
    TBD
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [ValidateSet('user','organizationalUnit','group','contact')]
        [string]$ObjectType,

        [Parameter()]
        [hashtable]$OtherAttributes,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        try {
            $OU = Get-DSOrganizationalUnit -Identity $Path -ResultsAs directoryentry @SearcherParams
            if ($null -eq $OU) {
                throw "Unable to find the path (ou): $Path"
            }
            else {
                Write-Verbose "$($FunctionName): Found OU Path $OU"
            }
        }
        catch {
            throw "Unable to find the path (ou): $Path"
        }

        $Prefix = 'cn='
        switch ($ObjectType) {
            {@('user','contact','group') -contains $_ } {
                $Prefix = 'cn='
            }
            'organizationalUnit' {
                $Prefix = 'ou='
            }
        }
        Write-Verbose "$($FunctionName): Prefix set to $Prefix"
    }
    process {
        $Identities += $Identity
    }
    end {
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Attempting to create $ObjectType with the name of $Prefix$ID"
            try {
                $NewObj = $OU.Create($ObjectType, "$Prefix$ID")
                if ($OtherAttributes) {
                    $OtherAttributes.Keys | ForEach-Object {
                        Write-Verbose "$($FunctionName): -- Setting additional attribute $($_) to $($OtherAttributes[$_])"
                        $NewObj.put($_, $OtherAttributes[$_])
                    }
                }

                Write-Verbose "$($FunctionName): Attempting to save the object.."
                $NewObj.SetInfo()
            }
            catch {
                $_
            }
        }
    }
}
