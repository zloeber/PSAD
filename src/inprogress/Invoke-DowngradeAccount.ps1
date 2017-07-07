function Invoke-DowngradeAccount {
<#
.SYNOPSIS
Set reversible encryption on a given account and then force the password to be set on next user login. To repair use "-Repair".

.DESCRIPTION
Set reversible encryption on a given account and then force the password to be set on next user login. To repair use "-Repair".

.PARAMETER SamAccountName
The SamAccountName of the domain object you're querying for. 

.PARAMETER Name
The Name of the domain object you're querying for.

.PARAMETER Domain
The domain to query for objects, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER Filter
Additional LDAP filter string for the query.

.PARAMETER Repair
Switch. Unset the reversible encryption flag and force password reset flag.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE
PS> Invoke-DowngradeAccount -SamAccountName jason

Set reversible encryption on the 'jason' account and force the password to be changed.

.EXAMPLE
PS> Invoke-DowngradeAccount -SamAccountName jason -Repair

Unset reversible encryption on the 'jason' account and remove the forced password change.
#>

    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName = 'SamAccountName', Position=0, ValueFromPipeline=$True)]
        [String]
        $SamAccountName,

        [Parameter(ParameterSetName = 'Name')]
        [String]
        $Name,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $Filter,

        [Switch]
        $Repair,

        [Management.Automation.PSCredential]
        $Credential
    )

    process {
        $Arguments = @{
            'SamAccountName' = $SamAccountName
            'Name' = $Name
            'Domain' = $Domain
            'DomainController' = $DomainController
            'Filter' = $Filter
            'Credential' = $Credential
        }

        # splat the appropriate arguments to Get-ADObject
        $UACValues = Get-ADObject @Arguments | select useraccountcontrol | ConvertFrom-UACValue

        if($Repair) {

            if($UACValues.Keys -contains "ENCRYPTED_TEXT_PWD_ALLOWED") {
                # if reversible encryption is set, unset it
                Set-ADObject @Arguments -PropertyName useraccountcontrol -PropertyXorValue 128
            }

            # unset the forced password change
            Set-ADObject @Arguments -PropertyName pwdlastset -PropertyValue -1
        }

        else {

            if($UACValues.Keys -contains "DONT_EXPIRE_PASSWORD") {
                # if the password is set to never expire, unset
                Set-ADObject @Arguments -PropertyName useraccountcontrol -PropertyXorValue 65536
            }

            if($UACValues.Keys -notcontains "ENCRYPTED_TEXT_PWD_ALLOWED") {
                # if reversible encryption is not set, set it
                Set-ADObject @Arguments -PropertyName useraccountcontrol -PropertyXorValue 128
            }

            # force the password to be changed on next login
            Set-ADObject @Arguments -PropertyName pwdlastset -PropertyValue 0
        }
    }
}