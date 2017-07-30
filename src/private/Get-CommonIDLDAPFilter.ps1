Function Get-CommonIDLDAPFilter {
	<#
    .SYNOPSIS
    A helper function for creating an LDAP filter for an AD object based on identity.
    .DESCRIPTION
	A helper function for creating an LDAP filter for an AD object based on identity.
    .PARAMETER Identity
	AD object to search for.
    .PARAMETER Filter
    LDAP filter for searches.

    .EXAMPLE
	NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
	#>
	[CmdletBinding()]
	param (
		[String]$Identity,
		[String[]]$Filter
	)
	# Function initialization
	if ($Script:ThisModuleLoaded) {
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	}

	if ([string]::IsNullOrEmpty($Identity)) {
		# If no identity is passed and no filter is passed then use a generic filter
		if ($Filter.Count -eq 0) {
			$Filter = @('distinguishedName=*')
		}
	}
	else {
		# Otherwise use OR logic with some fuzzy matching for the ID
		Write-Verbose "$($FunctionName): Identity passed ($ObjID), any existing filters will be ignored."
		$ObjID = Format-DSSearchFilterValue -SearchString $Identity

		# Do this to capture regular accounts as well as computer accounts (include a $ at the end)
		$SAMNameFilter = @("samaccountname=$ObjID","samaccountname=$ObjID$")
		$Filter = @("distinguishedName=$ObjID","objectGUID=$ObjID",,"cn=$ObjID") + (Get-CombinedLDAPFilter -Filter $SAMNameFilter -Conditional '|')
	}

	Get-CombinedLDAPFilter -Filter $Filter -Conditional '|'
}