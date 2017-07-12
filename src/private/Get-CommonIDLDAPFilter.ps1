Function Get-CommonIDLDAPFilter {
	param (
		[String]$Identity,
		[String[]]$Filter
	)

	if ([string]::IsNullOrEmpty($Identity)) {
			# If no identity is passed then use a generic filter
			if ($Filter.Count -eq 0) {
				$Filter = @('name=*')
			}
	}
	else {
			# Otherwise use OR logic with some fuzzy matching
			$ObjID = Format-DSSearchFilterValue -SearchString $Identity
			Write-Verbose "$($FunctionName): Identity passed, any existing filters will be ignored."
			$Filter = @("distinguishedName=$ObjID","objectGUID=$ObjID","samaccountname=$ObjID")
	}

	@($Filter | Select-Object -Unique)
}