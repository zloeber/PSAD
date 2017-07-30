function Get-DSObject {
    <#
    .SYNOPSIS
    Get AD objects of any kind.
    .DESCRIPTION
    Get AD objects of any kind. Used by most other functions for AD retrieval.
    .PARAMETER Identity
    Object to retreive. Accepts distinguishedname, GUID, and samAccountName.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .PARAMETER Limit
    Limits items retrieved. If set to 0 then there is no limit.
    .PARAMETER PageSize
    Items returned per page.
    .PARAMETER SearchRoot
    Root of search.
    .PARAMETER Filter
    Custom LDAP filters for searches. By default these are joined by logical AND.
    .PARAMETER BaseFilter
    In addition to custom filters use this as an immutable filter for searches.
    .PARAMETER ChangeLogicOrder
    Use logical OR instead of AND in custom LDAP filtering
    .PARAMETER Properties
    Properties to include in output. Is not used if ResultsAs is set to directoryentry.
    .PARAMETER SearchScope
    Scope of a search as either a base, one-level, or subtree search, default is subtree.
    .PARAMETER SecurityMask
    Specifies the available options for examining security information of a directory object.
    .PARAMETER TombStone
    Whether the search should also return deleted objects that match the search filter.
    .PARAMETER DontJoinAttributeValues
    Output will automatically join the attributes unless this switch is set.
    .PARAMETER IncludeAllProperties
    Include all properties for an object.
    .PARAMETER IncludeNullProperties
    Include unset (null) properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER ModifiedAfter
    Account was modified after this time
    .PARAMETER ModifiedBefore
    Account was modified before this time
    .PARAMETER CreatedAfter
    Account was created after this time
    .PARAMETER CreatedBefore
    Account was created before this time
    .PARAMETER ExpandUAC
    Expands the UAC attribute into readable format. Only effective if the ResultsAs parameter is psobject
    .PARAMETER Raw
    Skip attempts to convert known property types but still returns a psobject.
    .PARAMETER ResultsAs
    How the results are returned. psobject (which includes interpretted properties), directoryentry, or searcher. Default is psobject.
    .EXAMPLE
    TBD
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>

    [CmdletBinding()]
    [OutputType([object],[System.DirectoryServices.DirectoryEntry],[System.DirectoryServices.DirectorySearcher])]
    param(
        [Parameter( position = 0 , ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, HelpMessage='Object to retreive. Accepts distinguishedname, GUID, and samAccountName.')]
        [Alias('User', 'Name', 'sAMAccountName', 'distinguishedName')]
        [string]$Identity,

        [Parameter( position = 1, HelpMessage='Domain controller to use for this search.' )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(HelpMessage='Credentials to connect with.' )]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(HelpMessage='Limit results. If zero there is no limit.')]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter(HelpMessage='Root path to search.')]
        [string]$SearchRoot,

        [Parameter(HelpMessage='LDAP filters to use.')]
        [string[]]$Filter,

        [Parameter(HelpMessage='Immutable base ldap filter to use.')]
        [string]$BaseFilter,

        [Parameter(HelpMessage='LDAP properties to return')]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter(HelpMessage='Page size for larger results.')]
        [int]$PageSize = $Script:PageSize,

        [Parameter(HelpMessage='Type of search.')]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter(HelpMessage='Security mask for search.')]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter(HelpMessage='Include tombstone objects.')]
        [switch]$TombStone,

        [Parameter(HelpMessage='Use logical OR instead of AND for custom LDAP filters.')]
        [switch]$ChangeLogicOrder,

        [Parameter(HelpMessage='Only include objects modified after this date.')]
        [datetime]$ModifiedAfter,

        [Parameter(HelpMessage='Only include objects modified before this date.')]
        [datetime]$ModifiedBefore,

        [Parameter(HelpMessage='Only include objects created after this date.')]
        [datetime]$CreatedAfter,

        [Parameter(HelpMessage='Only include objects created before this date.')]
        [datetime]$CreatedBefore,

        [Parameter(HelpMessage='Do not joine attribute values in output.')]
        [switch]$DontJoinAttributeValues,

        [Parameter(HelpMessage='Include all properties that have a value')]
        [switch]$IncludeAllProperties,

        [Parameter(HelpMessage='Include null property values')]
        [switch]$IncludeNullProperties,

        [Parameter(HelpMessage='Expand useraccountcontroll property (if it exists).')]
        [switch]$ExpandUAC,

        [Parameter(HelpMessage='Do no property transformations in output.')]
        [switch]$Raw,

        [Parameter(HelpMessage='How you want the results to be returned.')]
        [ValidateSet('psobject', 'directoryentry', 'searcher')]
        [string]$ResultsAs = 'psobject'
    )

    Begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

    }
    Process {
        $SearcherParams = Get-CommonSearcherParams `
            -Identity $Identity `
            -ComputerName $ComputerName `
            -Credential $Credential `
            -Limit $Limit `
            -SearchRoot ($SearchRoot -replace 'LDAP://','') `
            -Filter $Filter `
            -BaseFilter $BaseFilter `
            -Properties $Properties `
            -PageSize $PageSize `
            -SearchScope $SearchScope `
            -SecurityMask $SecurityMask `
            -TombStone $TombStone `
            -ChangeLogicOrder $ChangeLogicOrder `
            -ModifiedAfter $ModifiedAfter `
            -ModifiedBefore $ModifiedBefore `
            -CreatedAfter $CreatedAfter `
            -CreatedBefore $CreatedBefore `
            -IncludeAllProperties $IncludeAllProperties `
            -IncludeNullProperties $IncludeNullProperties

        # Store for later reference
        try {
            $objSearcher = Get-DSDirectorySearcher @SearcherParams
        }
        catch {
            throw $_
        }

        switch ($ResultsAs) {
            'directoryentry' {
                $objSearcher.findall() | Foreach {
                    $_.GetDirectoryEntry()
                }
            }
            'searcher' {
                $objSearcher.findall()
            }
            'psobject' {
                $objSearcher.findall() | ForEach-Object {
                    $ObjectProps = @{}
                    $_.Properties.GetEnumerator() | Foreach-Object {
                        $Val = @($_.Value)
                        $Prop = $_.Name
                        if ($Prop -ne $null) {
                            if (-not $Raw) {
                                switch ($Prop) {
                                    'objectguid' {
                                        Write-Verbose "$($FunctionName): Reformatting objectguid"
                                        $Val = [guid]$Val[0]
                                    }
                                { @( 'objectsid', 'sidhistory' ) -contains $_ } {
                                        Write-Verbose "$($FunctionName): Reformatting $Prop"
                                        $Val = New-Object System.Security.Principal.SecurityIdentifier $Val[0], 0
                                    }
                                    'lastlogontimestamp' {
                                        Write-Verbose "$($FunctionName): Reformatting lastlogontimestamp"
                                        $Val = [datetime]::FromFileTimeUtc($Val[0])
                                    }
                                    'ntsecuritydescriptor' {
                                        Write-Verbose "$($FunctionName): Reformatting ntsecuritydescriptor"
                                        $Val = (New-Object System.DirectoryServices.ActiveDirectorySecurity).SetSecurityDescriptorBinaryForm($Val[0])
                                    }
                                    'usercertificate' {
                                        Write-Verbose "$($FunctionName): Reformatting usercertificate"
                                        $Val = foreach ($cert in $Val) {[Security.Cryptography.X509Certificates.X509Certificate2]$cert}
                                    }
                                    'accountexpires' {
                                        Write-Verbose "$($FunctionName): Reformatting accountexpires"
                                        try {
                                            if (($Val[0] -eq 0) -or ($Val[0] -gt [DateTime]::MaxValue.Ticks)) {
                                                $Val = '<Never>'
                                            }
                                            else {
                                                $Val = ([DateTime]$exval).AddYears(1600).ToLocalTime()
                                            }
                                        }
                                        catch {
                                            $Val = '<Never>'
                                        }
                                    }
                                    { @('pwdlastset', 'lastlogon', 'badpasswordtime') -contains $_ } {
                                        Write-Verbose "$($FunctionName): Reformatting $Prop"
                                        $Val = [dateTime]::FromFileTime($Val[0])
                                    }
                                    'objectClass' {
                                        Write-Verbose "$($FunctionName): Storing objectClass in case we need it for later."
                                        $objClass = $Val | Select-Object -Last 1
                                    }
                                    'Useraccountcontrol' {
                                        if ($ExpandUAC) {
                                            Write-Verbose "$($FunctionName): Expanding $Prop = $Val"
                                            $Val = Convert-DSUACProperty -UACProperty ([string]($Val[0]))
                                        }
                                        else {
                                            Write-Verbose "$($FunctionName): Leaving $Prop in the default format."
                                        }
                                    }
                                    'grouptype' {
                                        Write-Verbose "$($FunctionName): Changing $Prop into additional properties, groupcategory and groupscope"
                                        switch ($Val[0]) {
                                            2 {
                                                $ObjectProps.Add('GroupCategory','Distribution')
                                                $ObjectProps.Add('GroupScope','Global')
                                            }
                                            4 {
                                                $ObjectProps.Add('GroupCategory','Distribution')
                                                $ObjectProps.Add('GroupScope','Local')
                                            }
                                            8 {
                                                $ObjectProps.Add('GroupCategory','Distribution')
                                                $ObjectProps.Add('GroupScope','Universal')
                                            }
                                            -2147483646 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Global')
                                            }
                                            -2147483644 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Local')
                                            }
                                            -2147483640 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Global')
                                            }
                                            -2147483643 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Builtin')
                                            }
                                            Default {
                                                $ObjectProps.Add('GroupCategory',$null)
                                                $ObjectProps.Add('GroupScope',$null)
                                            }
                                        }
                                    }
                                    { @('gpcmachineextensionnames','gpcuserextensionnames') -contains $_ } {
                                        Write-Verbose "$($FunctionName): Reformatting $Prop"
                                        $Val = Convert-DSCSE -CSEString $Val[0]
                                    }
                                    Default {
                                        # try to convert misc objects as best we can
                                        if ($Val[0] -is [System.Byte[]]) {
                                            try {
                                                Write-Verbose "$($FunctionName): Attempting reformatting of System.Byte[] - $Prop"
                                                $Val = Convert-ArrayToGUID $Val[0]
                                                [Int32]$High = $Temp.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $Val[0], $null)
                                                [Int32]$Low  = $Temp.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $Val[0], $null)
                                                $Val = [Int64]("0x{0:x8}{1:x8}" -f $High, $Low)
                                            }
                                            catch {
                                                Write-Verbose "$($FunctionName): Unable to  reformat System.Byte[] - $Prop"
                                            }
                                        }
                                    }
                                }
                            }
                            if ($DontJoinAttributeValues -and ($Val.Count -gt 1)) {
                                $ObjectProps.Add($Prop,$Val)
                            }
                            else {
                                $ObjectProps.Add($Prop,($Val -join ';'))
                            }
                        }
                    }

                    # Only return results that have more than 0 properties
                    if ($ObjectProps.psbase.keys.count -ge 1) {
                        # if we include all or even null properties then we poll the schema for our object's possible properties
                        if ($IncludeAllProperties -or $IncludeNullProperties) {
                            if (-not ($Script:__ad_schema_info.ContainsKey($ObjClass))) {
                                Write-Verbose "$($FunctionName): Storing schema attributes for $ObjClass for the first time"
                                Write-Verbose "$($FunctionName): Object class being queried for in the schema = $objClass"
                                ($Script:__ad_schema_info).$ObjClass = @(((Get-DSCurrentConnectedSchema).FindClass($objClass)).OptionalProperties).Name
                            }
                            else {
                                Write-Verbose "$($FunctionName): $ObjClass schema properties already loaded"
                            }

                            if ($IncludeAllProperties -and $IncludeNullProperties) {
                                ($Script:__ad_schema_info).$ObjClass | Foreach {
                                    if (-not ($ObjectProps.ContainsKey($_))) {
                                        # If the property exists in the schema but not in the searcher results
                                        # then it gets assigned a null value.
                                        $ObjectProps.$_ = $null
                                    }
                                }
                            }
                            elseif ($IncludeNullProperties) {
                                ($Script:__ad_schema_info).$ObjClass | Where {$Properties -contains $_}| Foreach {
                                    if (-not ($ObjectProps.ContainsKey($_))) {
                                        # If the property exists in the schema and our passed properties but not in
                                        # the searcher results then it gets assigned a null value.
                                        # This eliminates properties that may get passed by a user but that
                                        # don't exist on object.
                                        $ObjectProps.$_ = $null
                                    }
                                }
                            }
                        }
                        if (-not $IncludeAllProperties) {
                            # We only want to return properties that actually exist on the object
                            $Properties2 = $Properties | Where {$null -ne $_} | Where {$ObjectProps.ContainsKey($_)}
                        }
                        else {
                            # Or all the properties
                            $Properties2 = '*'
                        }
                        if ($null -ne $Properties2) {
                            New-Object PSObject -Property $ObjectProps | Select-Object $Properties2
                        }
                    }
                }
            }
        }
    }
    end {
        # Avoid memory leaks
        $objSearcher.dispose()
    }
}
