function Get-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSObject.md
    #>
    [CmdletBinding()]
    param(
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
        [string[]]$Filter = 'name=*',

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
        [switch]$ReturnDirectoryEntry
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build filter
        $LDAPFilters = @($Filter | Select-Object -Unique)
        if ($ChangeLogicOrder) {
            $FinalLDAPFilter = "(&(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            $FinalLDAPFilter = "(&(&({0})))" -f ($LDAPFilters -join ')(')
        }

        if ($IncludeAllProperties) {
            $Properties = '*'
        }

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Credential = $Credential
            Filter = $FinalLDAPFilter
            Properties = $Properties
            SecurityMask = $SecurityMask
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
    }
    Process {
        Write-Verbose "$($FunctionName): Searching with filter: $LDAPFilter"

        $objSearcher = Get-DSDirectorySearcher @SearcherParams

        if ($ReturnDirectoryEntry) {
            $objSearcher.findall()
        }
        else {
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
    end {
        # Avoid memory leaks
        $objSearcher.dispose()
    }
}

