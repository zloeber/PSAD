function Get-DSGroupMember {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSGroupMember.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name','Group','GroupName')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$Recurse
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $BaseSearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }

        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $BaseSearcherParams.Tombstone = $true
        }
    }

    process {
        Write-Verbose "$($FunctionName): Trying to find the group - $Identity"
        try {
            $Identity = Format-DSSearchFilterValue -String $Identity
            $Group = Get-DSGroup @BaseSearcherParams -Identity $Identity -Properties @('distinguishedname','samaccountname')
        }
        catch {
            throw
            Write-Error "$($FunctionName): Error trying to find the group - $Identity"
        }

        if ($Group.distinguishedname -eq $null) {
            Write-Error "$($FunctionName): No group found with the name of $Identity"
            return
        }

        $GroupSearcherParams = $BaseSearcherParams.Clone()

        if ($Properties.count -ge 1) {
            $GroupSearcherParams.Properties = $Properties
        }
        if ($IncludeAllProperties) {
            $GroupSearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $GroupSearcherParams.DontJoinAttributeValues = $true
        }
        if ($Raw) {
            $GroupSearcherParams.Raw = $true
        }

        $Filter = @()
        if ($Recurse) {
            $Filter += "memberof:1.2.840.113556.1.4.1941:=$($Group.distinguishedname)"
        }
        else {
            $Filter += "memberof=$($Group.distinguishedname)"
        }

        Get-DSObject @GroupSearcherParams -Filter $Filter
    }
}

