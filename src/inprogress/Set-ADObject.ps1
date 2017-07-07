function Set-ADObject {
<#
.SYNOPSIS
Takes a SID, name, or SamAccountName to query for a specified
domain object, and then sets a specified 'PropertyName' to a
specified 'PropertyValue'.

.DESCRIPTION
Takes a SID, name, or SamAccountName to query for a specified
domain object, and then sets a specified 'PropertyName' to a
specified 'PropertyValue'.

.PARAMETER SID
The SID of the domain object you're querying for.

.PARAMETER Name
The Name of the domain object you're querying for.

.PARAMETER SamAccountName
The SamAccountName of the domain object you're querying for. 

.PARAMETER Domain
The domain to query for objects, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER Filter
Additional LDAP filter string for the query.

.PARAMETER PropertyName
The property name to set.

.PARAMETER PropertyValue
The value to set for PropertyName

.PARAMETER PropertyXorValue
Integer value to binary xor (-bxor) with the current int value.

.PARAMETER ClearValue
Switch. Clear the value of PropertyName

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE
PS C:\> Set-ADObject -SamAccountName matt.admin -PropertyName countrycode -PropertyValue 0

Set the countrycode for matt.admin to 0

.EXAMPLE
PS C:\> Set-ADObject -SamAccountName matt.admin -PropertyName useraccountcontrol -PropertyXorValue 65536

Set the password not to expire on matt.admin

.NOTES
TBD

.LINK
TBD
#>

    [CmdletBinding()]
    Param (
        [String]
        $SID,

        [String]
        $Name,

        [String]
        $SamAccountName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $Filter,

        [Parameter(Mandatory = $True)]
        [String]
        $PropertyName,

        $PropertyValue,

        [Int]
        $PropertyXorValue,

        [Switch]
        $ClearValue,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    $Arguments = @{
        'SID' = $SID
        'Name' = $Name
        'SamAccountName' = $SamAccountName
        'Domain' = $Domain
        'DomainController' = $DomainController
        'Filter' = $Filter
        'PageSize' = $PageSize
        'Credential' = $Credential
    }
    # splat the appropriate arguments to Get-ADObject
    $RawObject = Get-ADObject -ReturnRaw @Arguments
    
    try {
        # get the modifiable object for this search result
        $Entry = $RawObject.GetDirectoryEntry()
        
        if($ClearValue) {
            Write-Verbose "Clearing value"
            $Entry.$PropertyName.clear()
            $Entry.commitchanges()
        }

        elseif($PropertyXorValue) {
            $TypeName = $Entry.$PropertyName[0].GetType().name

            # UAC value references- https://support.microsoft.com/en-us/kb/305144
            $PropertyValue = $($Entry.$PropertyName) -bxor $PropertyXorValue 
            $Entry.$PropertyName = $PropertyValue -as $TypeName       
            $Entry.commitchanges()     
        }

        else {
            $Entry.put($PropertyName, $PropertyValue)
            $Entry.setinfo()
        }
    }
    catch {
        Write-Warning "Error setting property $PropertyName to value '$PropertyValue' for object $($RawObject.Properties.samaccountname) : $_"
    }
}
