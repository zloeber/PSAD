function ConvertFrom-UACValue {
<#
.SYNOPSIS
Converts a UAC int value to human readable form.

.DESCRIPTION
Converts a UAC int value to human readable form.

.PARAMETER Value
The int UAC value to convert.

.PARAMETER ShowAll
Show all UAC values, with a + indicating the value is currently set.

.PARAMETER TrueFalse
Shows each UAC property as true or false based on if it is set or not.

.PARAMETER AsObject
Default return is as an ordered dictionary, this switch returns a psobject instead.

.EXAMPLE
PS C:\> ConvertFrom-UACValue -Value 66176

Convert the UAC value 66176 to human readable format.

.EXAMPLE
PS C:\> Get-NetUser jason | select useraccountcontrol | ConvertFrom-UACValue

Convert the UAC value for 'jason' to human readable format.
.EXAMPLE

PS C:\> Get-NetUser jason | select useraccountcontrol | ConvertFrom-UACValue -ShowAll

Convert the UAC value for 'jason' to human readable format, showing all
possible UAC values.
#>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        $Value,

        [Parameter()]
        [Switch]
        $ShowAll,

        [Parameter()]
        [Switch]
        $TrueFalse,
        
        [Parameter()]
        [Switch]
        $AsObject
    )

    begin {
        # values from https://support.microsoft.com/en-us/kb/305144
        $UACValues = New-Object System.Collections.Specialized.OrderedDictionary
        $UACValues.Add("SCRIPT", 1)
        $UACValues.Add("ACCOUNTDISABLE", 2)
        $UACValues.Add("HOMEDIR_REQUIRED", 8)
        $UACValues.Add("LOCKOUT", 16)
        $UACValues.Add("PASSWD_NOTREQD", 32)
        $UACValues.Add("PASSWD_CANT_CHANGE", 64)
        $UACValues.Add("ENCRYPTED_TEXT_PWD_ALLOWED", 128)
        $UACValues.Add("TEMP_DUPLICATE_ACCOUNT", 256)
        $UACValues.Add("NORMAL_ACCOUNT", 512)
        $UACValues.Add("INTERDOMAIN_TRUST_ACCOUNT", 2048)
        $UACValues.Add("WORKSTATION_TRUST_ACCOUNT", 4096)
        $UACValues.Add("SERVER_TRUST_ACCOUNT", 8192)
        $UACValues.Add("DONT_EXPIRE_PASSWORD", 65536)
        $UACValues.Add("MNS_LOGON_ACCOUNT", 131072)
        $UACValues.Add("SMARTCARD_REQUIRED", 262144)
        $UACValues.Add("TRUSTED_FOR_DELEGATION", 524288)
        $UACValues.Add("NOT_DELEGATED", 1048576)
        $UACValues.Add("USE_DES_KEY_ONLY", 2097152)
        $UACValues.Add("DONT_REQ_PREAUTH", 4194304)
        $UACValues.Add("PASSWORD_EXPIRED", 8388608)
        $UACValues.Add("TRUSTED_TO_AUTH_FOR_DELEGATION", 16777216)
        $UACValues.Add("PARTIAL_SECRETS_ACCOUNT", 67108864)
    }

    process {

        $ResultUACValues = New-Object System.Collections.Specialized.OrderedDictionary

        if($Value -is [Int]) {
            $IntValue = $Value
        }
        elseif ($Value -is [PSCustomObject]) {
            if($Value.useraccountcontrol) {
                $IntValue = $Value.useraccountcontrol
            }
        }
        else {
            Write-Warning "Invalid object input for -Value : $Value"
            return $Null 
        }

        if($ShowAll) {
            foreach ($UACValue in $UACValues.GetEnumerator()) {
                if( ($IntValue -band $UACValue.Value) -eq $UACValue.Value) {
                    if ($TrueFalse){
                        $ResultUACValues.Add($UACValue.Name, $True)
                    }
                    else {
                        $ResultUACValues.Add($UACValue.Name, "$($UACValue.Value)+")
                    }
                }
                else {
                    if ($TrueFalse) {
                        $ResultUACValues.Add($UACValue.Name, $False)
                    }
                    else {
                        $ResultUACValues.Add($UACValue.Name, "$($UACValue.Value)")
                    }
                }
            }
        }
        else {
            foreach ($UACValue in $UACValues.GetEnumerator()) {
                if( ($IntValue -band $UACValue.Value) -eq $UACValue.Value) {
                    if ($TrueFalse) {
                        $ResultUACValues.Add($UACValue.Name, $true)
                    }
                    else {
                        $ResultUACValues.Add($UACValue.Name, "$($UACValue.Value)")
                    }
                }
            }
        }
        if ($AsObject) {
            New-Object PSObject -Property $ResultUACValues
        }
        else {
            $ResultUACValues
        }
    }
}