function Get-ComputerProperty {
<#
.SYNOPSIS
Returns a list of all computer object properties. If a property name is specified, it returns all [computer:property] values.

.DESCRIPTION
Returns a list of all computer object properties. If a property name is specified, it returns all [computer:property] values.

.PARAMETER Properties
Return property names for computers.

.PARAMETER Domain
The domain to query for computer properties, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE
PS C:\> Get-ComputerProperty -Domain testing

Returns all user properties for computers in the 'testing' domain.

.EXAMPLE
PS C:\> Get-ComputerProperty -Properties ssn,lastlogon,location

Returns all an array of computer/ssn/lastlogin/location combinations
for computers in the current domain.

.NOTES
Taken directly from @obscuresec's post:
    http://obscuresecurity.blogspot.com/2014/04/ADSISearcher.html
    
.LINK
http://obscuresecurity.blogspot.com/2014/04/ADSISearcher.html
#>

    [CmdletBinding()]
    param(
        [String[]]
        $Properties,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    if($Properties) {
        # extract out the set of all properties for each object
        $Properties = ,"name" + $Properties | Sort-Object -Unique
        Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -PageSize $PageSize | Select-Object -Property $Properties
    }
    else {
        # extract out just the property names
        Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -PageSize $PageSize | Select-Object -first 1 | Get-Member -MemberType *Property | Select-Object -Property "Name"
    }
}
