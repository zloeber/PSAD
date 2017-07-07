function Invoke-EnumerateLocalAdmin {
<#
.SYNOPSIS
This function queries the domain for all active machines with
Get-NetComputer, then for each server it queries the local
Administrators with Get-NetLocalGroup.

.DESCRIPTION
This function queries the domain for all active machines with
Get-NetComputer, then for each server it queries the local
Administrators with Get-NetLocalGroup.

.PARAMETER ComputerName

Host array to enumerate, passable on the pipeline.

.PARAMETER ComputerFile

File of hostnames/IPs to search.

.PARAMETER ComputerFilter

Host filter name to query AD for, wildcards accepted.

.PARAMETER ComputerADSpath

The LDAP source to search through for hosts, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER NoPing

Switch. Don't ping each host to ensure it's up before enumerating.

.PARAMETER Delay

Delay between enumerating hosts, defaults to 0

.PARAMETER Jitter

Jitter for the host delay, defaults to +/- 0.3

.PARAMETER OutFile

Output results to a specified csv output file.

.PARAMETER NoClobber

Switch. Don't overwrite any existing output file.

.PARAMETER TrustGroups

Switch. Only return results that are not part of the local machine
or the machine's domain. Old Invoke-EnumerateLocalTrustGroup
functionality.

.PARAMETER DomainOnly

Switch. Only return domain (non-local) results  

.PARAMETER Domain

Domain to query for machines, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER SearchForest

Switch. Search all domains in the forest for target users instead of just
a single domain.

.PARAMETER API

Switch. Use API calls instead of the WinNT service provider. Less information,
but the results are faster.

.PARAMETER Threads

The maximum concurrent threads to execute.

.EXAMPLE

PS C:\> Invoke-EnumerateLocalAdmin

Enumerates the members of local administrators for all machines
in the current domain.

.EXAMPLE

PS C:\> Invoke-EnumerateLocalAdmin -Threads 10

Threaded local admin enumeration, replaces Invoke-EnumerateLocalAdminThreaded

.LINK

http://blog.harmj0y.net/

.NOTES
Author: @harmj0y
License: BSD 3-Clause
#>

    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [Alias('Hosts')]
        [String[]]
        $ComputerName,

        [ValidateScript({Test-Path -Path $_ })]
        [Alias('HostList')]
        [String]
        $ComputerFile,

        [String]
        $ComputerFilter,

        [String]
        $ComputerADSpath,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $OutFile,

        [Switch]
        $NoClobber,

        [Switch]
        $TrustGroups,

        [Switch]
        $DomainOnly,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Switch]
        $API
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        # random object for delay
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-EnumerateLocalAdmin with delay of $Delay"

        # if we're using a host list, read the targets in and add them to the target list
        if($ComputerFile) {
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) { 
            [array]$ComputerName = @()

            if($Domain) {
                $TargetDomains = @($Domain)
            }
            elseif($SearchForest) {
                # get ALL the domains in the forest to search
                $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
            }
            else {
                # use the local domain
                $TargetDomains = @( (Get-NetDomain).name )
            }

            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for hosts"
                $ComputerName += Get-NetComputer -Filter $ComputerFilter -ADSpath $ComputerADSpath -Domain $Domain -DomainController $DomainController
            }
            
            # remove any null target hosts, uniquify the list and shuffle it
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        # delete any existing output file if it already exists
        if(!$NoClobber) {
            if ($OutFile -and (Test-Path -Path $OutFile)) { Remove-Item -Path $OutFile }
        }

        if($TrustGroups) {
            
            Write-Verbose "Determining domain trust groups"

            # find all group names that have one or more users in another domain
            $TrustGroupNames = Find-ForeignGroup -Domain $Domain -DomainController $DomainController | ForEach-Object { $_.GroupName } | Sort-Object -Unique

            $TrustGroupsSIDs = $TrustGroupNames | ForEach-Object { 
                # ignore the builtin administrators group for a DC (S-1-5-32-544)
                # TODO: ignore all default built in sids?
                Get-NetGroup -Domain $Domain -DomainController $DomainController -GroupName $_ -FullData | Where-Object { $_.objectsid -notmatch "S-1-5-32-544" } | ForEach-Object { $_.objectsid }
            }

            # query for the primary domain controller so we can extract the domain SID for filtering
            $DomainSID = Get-DomainSID -Domain $Domain -DomainController $DomainController
        }

        # script block that enumerates a server
        $HostEnumBlock = {
            param($ComputerName, $Ping, $OutFile, $DomainSID, $TrustGroupsSIDs, $API, $DomainOnly)

            # optionally check if the server is up first
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                # grab the users for the local admins on this server
                if($API) {
                    $LocalAdmins = Get-NetLocalGroup -ComputerName $ComputerName -API
                }
                else {
                    $LocalAdmins = Get-NetLocalGroup -ComputerName $ComputerName
                }

                # if we just want to return cross-trust users
                if($DomainSID) {
                    # get the local machine SID
                    $LocalSID = ($LocalAdmins | Where-Object { $_.SID -match '.*-500$' }).SID -replace "-500$"
                    Write-Verbose "LocalSid for $ComputerName : $LocalSID"
                    # filter out accounts that begin with the machine SID and domain SID
                    #   but preserve any groups that have users across a trust ($TrustGroupSIDS)
                    $LocalAdmins = $LocalAdmins | Where-Object { ($TrustGroupsSIDs -contains $_.SID) -or ((-not $_.SID.startsWith($LocalSID)) -and (-not $_.SID.startsWith($DomainSID))) }
                }

                if($DomainOnly) {
                    $LocalAdmins = $LocalAdmins | Where-Object {$_.IsDomain}
                }

                if($LocalAdmins -and ($LocalAdmins.Length -ne 0)) {
                    # output the results to a csv if specified
                    if($OutFile) {
                        $LocalAdmins | Export-PowerViewCSV -OutFile $OutFile
                    }
                    else {
                        # otherwise return the user objects
                        $LocalAdmins
                    }
                }
                else {
                    Write-Verbose "[!] No users returned from $ComputerName"
                }
            }
        }
    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            # if we're using threading, kick off the script block with Invoke-ThreadedFunction
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'OutFile' = $OutFile
                'DomainSID' = $DomainSID
                'TrustGroupsSIDs' = $TrustGroupsSIDs
            }

            # kick off the threaded script block + arguments
            if($API) {
                $ScriptParams['API'] = $True
            }

            if($DomainOnly) {
                $ScriptParams['DomainOnly'] = $True
            }
         
            Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
        }

        else {
            if(-not $NoPing -and ($ComputerName.count -ne 1)) {
                # ping all hosts in parallel
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                # sleep for our semi-randomized interval
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)
                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"

                $ScriptArgs = @($Computer, $False, $OutFile, $DomainSID, $TrustGroupsSIDs, $API, $DomainOnly)

                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $ScriptArgs
            }
        }
    }
}