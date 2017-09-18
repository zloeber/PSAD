function Get-DSObjectACL {
    <#
    .SYNOPSIS
    Get the security permissions for a given DN.
    .DESCRIPTION
    Get the security permissions for a given DN.
    .EXAMPLE
    PS C:\> Get-DSObjectAcl -Identity "DC=labcorp,DC=local" -SecurityMask 'Sacl' | where {$_.AccessControlType -eq 'DS-Replication-Synchronize'}
    Find all permissions on the root of the domain for DS-Replication-Synchronize permission.
    .OUTPUTS
    System.DirectoryServices.ActiveDirectoryAccessRule
    .NOTES
    The first time this runs it enumerates all the GUIDs for permissions in the domain and can take quite a while.
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $ThisDomain = (Split-Credential -Credential $Credential).Domain
        $ThisForest = (Get-DSDomain -Identity $ThisDomain -Credential $Credential -ComputerName $ComputerName).Forest.Name
        Write-Verbose "Forest - $ThisForest"
        Get-GUIDMap -Forest $ThisForest -ComputerName $ComputerName -Credential $Credential

        $ACLOutput = @(
            @{'n'='DistingquishedName';'e'={$DN}},
            'ActiveDirectoryRights',
            'InheritanceType',
            @{'n'='ObjectType';'e'={$Script:GUIDMap[$ThisForest][$_.ObjectType.Guid]}},
            @{'n'='InheritedObjectType';'e'={$Script:GUIDMap[$ThisForest][$_.InheritedObjectType.Guid]}},
            'ObjectFlags',
            'AccessControlType',
            'IdentityReference',
            'IsInherited',
            'InheritanceFlags',
            'PropagationFlags'
        )
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }

        $Identities += $Identity
        $GetObjectParams.Properties = @('DistinguishedName')
        $GetObjectParams.ResultsAs = 'directoryentry'

        if ($null -eq $GetObjectParams.SecurityMask) {
            $GetObjectParams.SecurityMask = @('Dacl','Group','Owner')
            Write-Verbose "$($FunctionName): Since no security mask was set we will enable non-admin capable flags only (Dacl, Group, Owner)."
        }
    }
    end {
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | Foreach {
                $DN = $_.properties.distinguishedname[0]
                Write-Verbose "$($FunctionName): Found $DN"
                $_.PsBase.ObjectSecurity.Access | Select $ACLOutput
            }
        }
    }
}
