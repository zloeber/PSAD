Function Get-DistinguishedNameFromFQDN {
    <#
    .SYNOPSIS
    TBD

    .DESCRIPTION
    TBD

    .PARAMETER fqdn
    fqdn explanation

    .EXAMPLE
    TBD
    #>

	param (
		[String]$fqdn = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
	)

	# Create a New Array 'Item' for each item in between the '.' characters
	# Arrayitem1 division
	# Arrayitem2 domain
	# Arrayitem3 root
	$FQDNArray = $FQDN.split(".")
	
	# Add A Separator of ','
	$Separator = ","

	# For Each Item in the Array
	# for (CreateVar; Condition; RepeatAction)
	# for ($x is now equal to 0; while $x is less than total array length; add 1 to X
	for ($x = 0; $x -lt $FQDNArray.Length ; $x++)
		{ 

		#If it's the last item in the array don't append a ','
		if ($x -eq ($FQDNArray.Length - 1)) { $Separator = "" }
		
		# Append to $DN DC= plus the array item with a separator after
		[string]$DN += "DC=" + $FQDNArray[$x] + $Separator
		
		# continue to next item in the array
		}
	
	#return the Distinguished Name
	return $DN

}
