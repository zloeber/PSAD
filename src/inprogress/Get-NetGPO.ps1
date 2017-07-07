function Get-NetGPO {
<#
.SYNOPSIS
Gets a list of all current GPOs in a domain.

.DESCRIPTION
Gets a list of all current GPOs in a domain.

.PARAMETER GPOname

The GPO name to query for, wildcards accepted.   

.PARAMETER DisplayName

The GPO display name to query for, wildcards accepted.   

.PARAMETER ComputerName

Return all GPO objects applied to a given computer (FQDN).

.PARAMETER Domain

The domain to query for GPOs, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER ADSpath

The LDAP source to search through
e.g. "LDAP://cn={8FF59D28-15D7-422A-BCB7-2AE45724125A},cn=policies,cn=system,DC=dev,DC=testlab,DC=local"

.PARAMETER PageSize

The PageSize to set for the LDAP searcher object.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

PS C:\> Get-NetGPO -Domain testlab.local

Returns the GPOs in the 'testlab.local' domain. 
#>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GPOname = '*',

        [String]
        $DisplayName,

        [String]
        $ComputerName,

        [String]
        $Domain,

        [String]
        $DomainController,
        
        [String]
        $ADSpath,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {
        $GPOSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $ADSpath -PageSize $PageSize
    }

    process {
        if ($GPOSearcher) {

            if($ComputerName) {
                $GPONames = @()
                $Computers = Get-NetComputer -ComputerName $ComputerName -Domain $Domain -DomainController $DomainController -FullData -PageSize $PageSize

                if(!$Computers) {
                    throw "Computer $ComputerName in domain '$Domain' not found! Try a fully qualified host name"
                }
                
                # get the given computer's OU
                $ComputerOUs = @()
                ForEach($Computer in $Computers) {
                    # extract all OUs a computer is a part of
                    $DN = $Computer.distinguishedname

                    $ComputerOUs += $DN.split(",") | ForEach-Object {
                        if($_.startswith("OU=")) {
                            $DN.substring($DN.indexof($_))
                        }
                    }
                }
                
                Write-Verbose "ComputerOUs: $ComputerOUs"

                # find all the GPOs linked to the computer's OU
                ForEach($ComputerOU in $ComputerOUs) {
                    $GPONames += Get-NetOU -Domain $Domain -DomainController $DomainController -ADSpath $ComputerOU -FullData -PageSize $PageSize | ForEach-Object { 
                        # get any GPO links
                        write-verbose "blah: $($_.name)"
                        $_.gplink.split("][") | ForEach-Object {
                            if ($_.startswith("LDAP")) {
                                $_.split(";")[0]
                            }
                        }
                    }
                }
                
                Write-Verbose "GPONames: $GPONames"

                # find any GPOs linked to the site for the given computer
                $ComputerSite = (Get-SiteName -ComputerName $ComputerName).SiteName
                if($ComputerSite -and ($ComputerSite -notlike 'Error*')) {
                    $GPONames += Get-NetSite -SiteName $ComputerSite -FullData | ForEach-Object {
                        if($_.gplink) {
                            $_.gplink.split("][") | ForEach-Object {
                                if ($_.startswith("LDAP")) {
                                    $_.split(";")[0]
                                }
                            }
                        }
                    }
                }

                $GPONames | Where-Object{$_ -and ($_ -ne '')} | ForEach-Object {

                    # use the gplink as an ADS path to enumerate all GPOs for the computer
                    $GPOSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $_ -PageSize $PageSize
                    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(name=$GPOname))"

                    try {
                        $Results = $GPOSearcher.FindAll()
                        $Results | Where-Object {$_} | ForEach-Object {
                            $Out = Convert-LDAPProperty -Properties $_.Properties
                            $Out | Add-Member Noteproperty 'ComputerName' $ComputerName
                            $Out
                        }
                        $Results.dispose()
                        $GPOSearcher.dispose()
                    }
                    catch {
                        Write-Warning $_
                    }
                }
            }

            else {
                if($DisplayName) {
                    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(displayname=$DisplayName))"
                }
                else {
                    $GPOSearcher.filter="(&(objectCategory=groupPolicyContainer)(name=$GPOname))"
                }

                try {
                    $Results = $GPOSearcher.FindAll()
                    $Results | Where-Object {$_} | ForEach-Object {
                        if($ADSPath -and ($ADSpath -Match '^GC://')) {
                            $Properties = Convert-LDAPProperty -Properties $_.Properties
                            try {
                                $GPODN = $Properties.distinguishedname
                                $GPODomain = $GPODN.subString($GPODN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                                $gpcfilesyspath = "\\$GPODomain\SysVol\$GPODomain\Policies\$($Properties.cn)"
                                $Properties | Add-Member Noteproperty 'gpcfilesyspath' $gpcfilesyspath
                                $Properties
                            }
                            catch {
                                $Properties
                            }
                        }
                        else {
                            # convert/process the LDAP fields for each result
                            Convert-LDAPProperty -Properties $_.Properties
                        }
                    }
                    $Results.dispose()
                    $GPOSearcher.dispose()
                }
                catch {
                    Write-Warning $_
                }
            }
        }
    }
}