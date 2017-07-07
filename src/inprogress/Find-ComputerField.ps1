function Find-ComputerField {
<#
.SYNOPSIS
Searches computer object fields for a given word (default *pass*). Default
field being searched is 'description'.

.DESCRIPTION
Searches computer object fields for a given word (default *pass*). Default
field being searched is 'description'.

.PARAMETER SearchTerm
Term to search for, default of "pass".

.PARAMETER SearchField
User field to search in, default of "description".

.PARAMETER ADSpath
The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER Domain
Domain to search computer fields for, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER PageSize
The PageSize to set for the LDAP searcher object.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE
PS C:\> Find-ComputerField -SearchTerm backup -SearchField info

Find computer accounts with "backup" in the "info" field.

.NOTES
Taken directly from @obscuresec's post:
http://obscuresecurity.blogspot.com/2014/04/ADSISearcher.html
#>

    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Term')]
        [String]
        $SearchTerm = 'pass',

        [Alias('Field')]
        [String]
        $SearchField = 'description',

        [String]
        $ADSpath,

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

    process {
        Get-NetComputer -ADSpath $ADSpath -Domain $Domain -DomainController $DomainController -Credential $Credential -FullData -Filter "($SearchField=*$SearchTerm*)" -PageSize $PageSize | Select-Object samaccountname,$SearchField
    }
}