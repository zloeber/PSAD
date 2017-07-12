function Get-DSDomain {
    <#
    .SYNOPSIS
    Retrieve an ADSI domain object.
    .DESCRIPTION
    Retrieve an ADSI domain object.
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving domain information.
    .PARAMETER Identity
    Forest name to retreive.
    .PARAMETER UpdateCurrent
    Updates the module stored currently connected forest object
    .EXAMPLE
    C:\PS> Get-DSDomain
    Get information on the current domain the machine is a member of.
    .OUTPUTS
    System.DirectoryServices.ActiveDirectory.Domain
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name','Domain','DomainName')]
        [string]$Identity = ($Script:CurrentDomain).name,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [switch]$UpdateCurrent
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    Process {
        try {
            $context = Get-DSDirectoryContext -ContextType 'Domain' -ContextName $DomainName -ComputerName $ComputerName -Credential $Credential
            $DomainObject = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)

            $RootDN = "DC=$(($DomainObject.Name).replace('.',',DC='))"
            $DEObj = Get-DSDirectoryEntry -DistinguishedName $RootDN -ComputerName $ComputerName -Credential $Credential
            $Sid = (New-Object -TypeName System.Security.Principal.SecurityIdentifier($DEObj.objectSid.value,0)).value
            $guid = "$([guid]($DEObj.objectguid.Value))"

            Add-Member -InputObject $DomainObject -MemberType NoteProperty -Name 'Sid' -Value $Sid
            Add-Member -InputObject $DomainObject -MemberType NoteProperty -Name 'Guid' -Value $guid

            if ($UpdateCurrent) {
                $Script:CurrentDomain = $DomainObject
            }
            else {
                $DomainObject
            }
        }
        catch {
            throw
        }
    }
}
