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
    LDAP filter for searches.
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
    Include all optional properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER ExpandUAC
    Expands the UAC attribute into readable format. Only effective if the ResultsAs parameter is psobject
    .PARAMETER Raw
    Skip attempts to convert known property types but still returns a psobject.
    .PARAMETER ResultsAs
    How the results are returned. psobject (which includes interpretted properties), directoryentry, or searcher. Default is psobject.
    .PARAMETER ChangeLogicOrder
    Use logical OR instead of AND in LDAP filtering
    .EXAMPLE
    TBD
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [SupportsWildcards()]
        [Alias('Name')]
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
        [string[]]$Filter,

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
        [switch]$ExpandUAC,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [ValidateSet('psobject', 'directoryentry', 'searcher')]
        [string]$ResultsAs = 'psobject'
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Credential = $Credential
            Properties = $Properties
            SecurityMask = $SecurityMask
        }
    }
    Process {
        # Build the filter
        $LDAPFilters = Get-CommonIDLDAPFilter -Identity $Identity -Filter $Filter
        if (-not [string]::IsNullOrEmpty($Identity)) {
            # If an identity was passed then change to or logic
            $ChangeLogicOrder = $true
        }

        if ($ChangeLogicOrder) {
            Write-Verbose "$($FunctionName): Combining filters with OR logic."
            $SearcherParams.Filter = "(&(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            Write-Verbose "$($FunctionName): Combining filters with AND logic."
            $SearcherParams.Filter = "(&(&({0})))" -f ($LDAPFilters -join ')(')
        }

        if ($IncludeAllProperties) {
            Write-Verbose "$($FunctionName): Including all properties. Any passed properties will be ignored."
            $SearcherParams.Properties = '*'
        }

        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }

        # If a limit is set then use it to limit our results, otherwise use the page size (which doesn't limit results)
        if ($Limit -ne 0) {
            $SearcherParams.Limit = $Limit
        }
        else {
            $SearcherParams.PageSize = $PageSize
        }

        # Store the search settings for later inspection if required
        $Script:LastSearchSetting = $SearcherParams

        Write-Verbose "$($FunctionName): Searching with filter: $LDAPFilter"

        $objSearcher = Get-DSDirectorySearcher @SearcherParams
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
                        if ($IncludeAllProperties) {
                            if (-not ($Script:__ad_schema_info.ContainsKey($ObjClass))) {
                                Write-Verbose "$($FunctionName): Storing schema attributes for $ObjClass for the first time"
                                Write-Verbose "$($FunctionName): Object class being queried for in the schema = $objClass"
                                ($Script:__ad_schema_info).$ObjClass = @(((Get-DSCurrentConnectedSchema).FindClass($objClass)).OptionalProperties).Name
                            }
                            else {
                                Write-Verbose "$($FunctionName): $ObjClass schema properties already loaded"
                            }

                            ($Script:__ad_schema_info).$ObjClass | Foreach {
                                if (-not ($ObjectProps.ContainsKey($_))) {
                                    $ObjectProps.$_ = $null
                                }
                            }
                        }

                        New-Object PSObject -Property $ObjectProps | Select-Object $Properties
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
