# A dictionary with basic information about attributes (read from schema)
$global:__ad_schema_info=@{}
 
# Gets information about the attribute with the given name
function GetAttributeInfo([string] $name) {
    $key = $name.ToLowerInvariant()
    $attributeInfo = $global:__ad_schema_info[$key]
    if ($attributeInfo -eq $null) {
        Write-Verbose "Reading AD schema information for attribute $name"
        $rootDSE = [adsi]"LDAP://rootDSE"
        $query = new-object system.directoryservices.directorysearcher
        $query.SearchRoot = "LDAP://$($rootDSE.schemaNamingContext)"
        $query.PageSize = 1000
        $query.filter = "(&(objectClass=attributeSchema)(ldapDisplayName=$name))"
        $query.SearchScope = "onelevel"
        $query.PropertiesToLoad.Clear() | Out-Null
        $query.PropertiesToLoad.Add("issinglevalued") | Out-Null
        $query.PropertiesToLoad.Add("ldapdisplayname") | Out-Null
        $query.PropertiesToLoad.Add("attributeSyntax") | Out-Null
        $query.findAll() | % {
            $ldapdisplayname = $_.Properties.Item("ldapdisplayname")[0]
            $key = $ldapdisplayname.ToLowerInvariant()
            $issinglevalued = $_.Properties.Item("issinglevalued")[0]
            $syntax = $_.Properties.Item("attributeSyntax")[0]
            $attributeInfo = New-Object PSObject
            Add-Member -InputObject $attributeInfo -MemberType NoteProperty -Name "Name" -Value $ldapdisplayname
            Add-Member -InputObject $attributeInfo -MemberType NoteProperty -Name "IsSingleValue" -Value $issinglevalued
            Add-Member -InputObject $attributeInfo -MemberType NoteProperty -Name "Syntax" -Value "$syntax"
            Write-Verbose "$ldapdisplayname => $syntax, $issinglevalued"
            $global:__ad_schema_info[$key]=$attributeInfo
        }
        $query.Dispose()
    }
    $attributeInfo
}
 
# Object with constant values for syntaxed
$global:__AD_Attribute_Syntax = New-Object PSObject @{
    OCTET_STRING = "2.5.5.10"
}
 
# Converts a SearchResult object into a PSObject, which is easier to use in 
# PowerShell
# Note: adding attributes one by one so that they appear in alphabetical order
# when the object is written to the output. This is not the case if we use
#     New-Object PSObject -Property $dictionaryWithAttributes
function ResultExportObject() {
    process {
        $result = $_
        $propertyNames = $result.Properties.PropertyNames | Sort-Object 
        $obj = New-Object PSObject
        foreach ($name in $propertyNames) {
            if ($name.ToUpperInvariant() -eq "ADSPATH") {
                # skip the adspath, which makes things difficult to read
                # as it can be very long
                continue
            }
            $attributeInfo = GetAttributeInfo $name
            if ($attributeInfo.Syntax -eq $script:__AD_Attribute_Syntax.OCTET_STRING) {
                # skip octet string attributes, as each of them has a different
                # and specific meaning
                continue
            } elseif ($attributeInfo.IsSingleValue) {
                $value = $result.Properties.Item($name)[0]
            } else {
                $value = @($result.Properties.Item($name))
            }
            Add-Member -InputObject $obj -MemberType NoteProperty -Name $name -Value $value 
        }
        $obj
    }
}
 
<#
.SYNOPSIS
    Runs and LDAP Query.
.PARAMETER filter
    The ldap search filter.
.PARAMETER attributes
    The list of attributes. 
    If not specified, returns all attributes.
.PARAMETER root
    The search root (DN or adspath). 
    If not specified, uses the domain's root (default naming context).
.PARAMETER max
    Maximum number of results to return. 
    If not specifies, returns all results.
.PARAMETER count
    If specified, return only the number of objects.
.DESCRIPTION
    Runs and LDAP Query and turns the results in PSObjects. 
    It is possible specify which attributes should be returned and the search base.
.LINK
    Creating a Query Filter (ldap query syntax): http://msdn.microsoft.com/en-us/library/ms675768%28v=vs.85%29.aspx 
.EXAMPLE
ldp.ps1 "(&(objectClass=user)(!uidNumber=*)(whenCreated>=20101121000000.0Z))" -attributes sAMAccountName,employeeType,whenCreated -root "OU=Users,OU=Organic Units,DC=cern,DC=ch" | foreach {"$($_.sAMAccountName), $($_.employeeType), $($_.whenCreated | Get-Date -Format 'yyyy MM dd')"}
Get all accounts without UID created after 21/11/2010 and write to a .csv file
#>
function ldp {
    [CmdletBinding()]
    param(
        [string] $filter,
        [string[]] $attributes,
        [string] $root,
        [int] $max = 0,
        [switch] $xldap,
        [switch] $count)
 
    if ([string]::IsNullOrEmpty($root)) {
        $rootDSE = [adsi]"LDAP://rootDSE"
        $searchBase = "LDAP://$($rootDSE.defaultNamingContext)"
    } else {
        if (-not $root.StartsWith("LDAP://")) {
            $searchBase = [adsi]"LDAP://$root"
        } else {
            $searchBase = [adsi]"$root"
        }        
    }
 
    Write-Verbose "Filter = $filter"
    Write-Verbose "Root = $root"
 
    $query = new-object system.directoryservices.directorysearcher
    $query.SearchRoot = $searchBase
    $query.PageSize = 1000
    if ($max -ne 0) {
        $query.SizeLimit = $max
    }
    if (-not [string]::IsNullOrEmpty($filter)) {
        $query.filter = $filter
    }
    $query.SearchScope = "subtree"
    if ($attributes) {
        $query.PropertiesToLoad.Clear() | Out-Null
        $query.PropertiesToLoad.AddRange($attributes)
    }
    if ($count) {
        $query.PropertiesToLoad.Clear() | Out-Null
    }
    if ($count) {
      $res = $query.findAll()
      $res.count
    } else {
        if ($xldap) {
            $query.findAll() | ResultExportObject
        } else {
            $query.findAll() | ResultExportObject
        }
    }
    $query.Dispose()
}