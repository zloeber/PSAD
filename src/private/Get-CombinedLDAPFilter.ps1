Function Get-CombinedLDAPFilter {
	<#
    .SYNOPSIS
    A helper function for combining LDAP filters.
    .DESCRIPTION
	A helper function for combining LDAP filters.
    .PARAMETER Filter
	LDAP filters to combine.
	.PARAMETER Conditional
	AD object to search for.

    .EXAMPLE
	NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
	#>
	[CmdletBinding()]
	param (
		[Parameter( Position = 0, ValueFromPipeline = $True )]
		[String[]]$Filter,
		[Parameter( Position = 1 )]
		[String]$Conditional = '&'
	)
	begin {
		# Function initialization
		if ($Script:ThisModuleLoaded) {
			Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		}
		$FunctionName = $MyInvocation.MyCommand.Name
		$Filters = @()
	}
	process {
		$Filters += $Filter
	}

	end {
		$Filters = $Filters | Where-Object {-not [string]::IsNullOrEmpty($_)} | Select-Object -Unique
		Write-Verbose "$($FunctionName): All passed filters = $($Filters -join ', ')"
		switch ($Filters.Count) {
			0 {
				Write-Verbose "$($FunctionName): No filters passed, returning nothing."
				$FinalFilter = $null
			}
			1 {
				Write-Verbose "$($FunctionName): One filter passed, NOT using conditional."
				$FinalFilter = "($Filters)"
			}
			Default {
				Write-Verbose "$($FunctionName): Multiple filters passed, using conditional ($Conditional)."
				$FinalFilter = "($Conditional({0}))" -f ($Filters -join ')(')
			}
		}

		Write-Verbose "$($FunctionName): Final combined filter = $FinalFilter"
		$FinalFilter
	}
}