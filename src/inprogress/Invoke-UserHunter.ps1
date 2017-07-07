function Invoke-UserHunter {
<#
.SYNOPSIS
Finds which machines users of a specified group are logged into.

.DESCRIPTION
This function finds the local domain name for a host using Get-NetDomain,
queries the domain for users of a specified group (default "domain admins")
with Get-NetGroupMember or reads in a target user list, queries the domain for all
active machines with Get-NetComputer or reads in a pre-populated host list,
randomly shuffles the target list, then for each server it gets a list of
active users with Get-NetSession/Get-NetLoggedon. The found user list is compared
against the target list, and a status message is displayed for any hits.
The flag -CheckAccess will check each positive host to see if the current
user has local admin access to the machine.

.PARAMETER ComputerName
Host array to enumerate, passable on the pipeline.

.PARAMETER ComputerFile
File of hostnames/IPs to search.

.PARAMETER ComputerFilter
Host filter name to query AD for, wildcards accepted.

.PARAMETER ComputerADSpath
The LDAP source to search through for hosts, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER Unconstrained
Switch. Only enumerate computers that have unconstrained delegation.

.PARAMETER GroupName
Group name to query for target users.

.PARAMETER TargetServer
Hunt for users who are effective local admins on a target server.

.PARAMETER UserName
Specific username to search for.

.PARAMETER UserFilter
A customized ldap filter string to use for user enumeration, e.g. "(description=*admin*)"

.PARAMETER UserADSpath
The LDAP source to search through for users, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER UserFile
File of usernames to search for.

.PARAMETER AdminCount
Switch. Hunt for users with adminCount=1.

.PARAMETER AllowDelegation
Switch. Return user accounts that are not marked as 'sensitive and not allowed for delegation'

.PARAMETER StopOnSuccess
Switch. Stop hunting after finding after finding a target user.

.PARAMETER NoPing
Don't ping each host to ensure it's up before enumerating.

.PARAMETER CheckAccess
Switch. Check if the current user has local admin access to found machines.

.PARAMETER Delay
Delay between enumerating hosts, defaults to 0

.PARAMETER Jitter
Jitter for the host delay, defaults to +/- 0.3

.PARAMETER Domain
Domain for query for machines, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER ShowAll
Switch. Return all user location results, i.e. Invoke-UserView functionality.

.PARAMETER SearchForest
Switch. Search all domains in the forest for target users instead of just
a single domain.

.PARAMETER Stealth
Switch. Only enumerate sessions from connonly used target servers.

.PARAMETER StealthSource
The source of target servers to use, 'DFS' (distributed file servers),
'DC' (domain controllers), 'File' (file servers), or 'All'

.PARAMETER ForeignUsers
Switch. Only return results that are not part of searched domain.

.PARAMETER Threads
The maximum concurrent threads to execute.

.PARAMETER Poll
Continuously poll for sessions for the given duration. Automatically
sets Threads to the number of computers being polled.

.EXAMPLE
PS C:\> Invoke-UserHunter -CheckAccess

Finds machines on the local domain where domain admins are logged into
and checks if the current user has local administrator access.

.EXAMPLE
PS C:\> Invoke-UserHunter -Domain 'testing'

Finds machines on the 'testing' domain where domain admins are logged into.

.EXAMPLE
PS C:\> Invoke-UserHunter -Threads 20

Multi-threaded user hunting, replaces Invoke-UserHunterThreaded.

.EXAMPLE
PS C:\> Invoke-UserHunter -UserFile users.txt -ComputerFile hosts.txt

Finds machines in hosts.txt where any members of users.txt are logged in
or have sessions.

.EXAMPLE
PS C:\> Invoke-UserHunter -GroupName "Power Users" -Delay 60

Find machines on the domain where members of the "Power Users" groups are
logged into with a 60 second (+/- *.3) randomized delay between
touching each host.

.EXAMPLE
PS C:\> Invoke-UserHunter -TargetServer FILESERVER

Query FILESERVER for useres who are effective local administrators using
Get-NetLocalGroup -Recurse, and hunt for that user set on the network.

.EXAMPLE
PS C:\> Invoke-UserHunter -SearchForest

Find all machines in the current forest where domain admins are logged in.

.EXAMPLE
PS C:\> Invoke-UserHunter -Stealth

Executes old Invoke-StealthUserHunter functionality, enumerating commonly
used servers and checking just sessions for each.

.EXAMPLE
PS C:\> Invoke-UserHunter -Stealth -StealthSource DC -Poll 3600 -Delay 5 -ShowAll | ? { ! $_.UserName.EndsWith('$') }

Poll Domain Controllers in parallel for sessions for an hour, waiting five
seconds before querying each DC again and filtering out computer accounts.

.NOTES
Author: @harmj0y
License: BSD 3-Clause

.LINK
http://blog.harmj0y.net
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
        $Unconstrained,

        [String]
        $GroupName = 'Domain Admins',

        [String]
        $TargetServer,

        [String]
        $UserName,

        [String]
        $UserFilter,

        [String]
        $UserADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $UserFile,

        [Switch]
        $AdminCount,

        [Switch]
        $AllowDelegation,

        [Switch]
        $CheckAccess,

        [Switch]
        $StopOnSuccess,

        [Switch]
        $NoPing,

        [UInt32]
        $Delay = 0,

        [Double]
        $Jitter = .3,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $ShowAll,

        [Switch]
        $SearchForest,

        [Switch]
        $Stealth,

        [String]
        [ValidateSet("DFS","DC","File","All")]
        $StealthSource ="All",

        [Switch]
        $ForeignUsers,

        [Int]
        [ValidateRange(1,100)]
        $Threads,

        [UInt32]
        $Poll = 0
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        Write-Verbose "[*] Running Invoke-UserHunter with delay of $Delay"

        #####################################################
        #
        # First we build the host target set
        #
        #####################################################

        if($ComputerFile) {
            # if we're using a host list, read the targets in and add them to the target list
            $ComputerName = Get-Content -Path $ComputerFile
        }

        if(!$ComputerName) { 
            [Array]$ComputerName = @()

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
            
            if($Stealth) {
                Write-Verbose "Stealth mode! Enumerating commonly used servers"
                Write-Verbose "Stealth source: $StealthSource"

                ForEach ($Domain in $TargetDomains) {
                    if (($StealthSource -eq "File") -or ($StealthSource -eq "All")) {
                        Write-Verbose "[*] Querying domain $Domain for File Servers..."
                        $ComputerName += Get-NetFileServer -Domain $Domain -DomainController $DomainController
                    }
                    if (($StealthSource -eq "DFS") -or ($StealthSource -eq "All")) {
                        Write-Verbose "[*] Querying domain $Domain for DFS Servers..."
                        $ComputerName += Get-DFSshare -Domain $Domain -DomainController $DomainController | ForEach-Object {$_.RemoteServerName}
                    }
                    if (($StealthSource -eq "DC") -or ($StealthSource -eq "All")) {
                        Write-Verbose "[*] Querying domain $Domain for Domain Controllers..."
                        $ComputerName += Get-NetDomainController -LDAP -Domain $Domain -DomainController $DomainController | ForEach-Object { $_.dnshostname}
                    }
                }
            }
            else {
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for hosts"

                    $Arguments = @{
                        'Domain' = $Domain
                        'DomainController' = $DomainController
                        'ADSpath' = $ADSpath
                        'Filter' = $ComputerFilter
                        'Unconstrained' = $Unconstrained
                    }

                    $ComputerName += Get-NetComputer @Arguments
                }
            }

            # remove any null target hosts, uniquify the list and shuffle it
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        if ($Poll -gt 0) {
            Write-Verbose "[*] Polling for $Poll seconds. Automatically enabling threaded mode."
            if ($ComputerName.Count -gt 100) {
                throw "Too many hosts to poll! Try fewer than 100."
            }
            $Threads = $ComputerName.Count
        }

        #####################################################
        #
        # Now we build the user target set
        #
        #####################################################

        # users we're going to be searching for
        $TargetUsers = @()

        # get the current user so we can ignore it in the results
        $CurrentUser = ([Environment]::UserName).toLower()

        # if we're showing all results, skip username enumeration
        if($ShowAll -or $ForeignUsers) {
            $User = New-Object PSObject
            $User | Add-Member Noteproperty 'MemberDomain' $Null
            $User | Add-Member Noteproperty 'MemberName' '*'
            $TargetUsers = @($User)

            if($ForeignUsers) {
                # if we're searching for user results not in the primary domain
                $krbtgtName = Convert-ADName -ObjectName "krbtgt@$($Domain)" -InputType Simple -OutputType NT4
                $DomainShortName = $krbtgtName.split("\")[0]
            }
        }
        # if we want to hunt for the effective domain users who can access a target server
        elseif($TargetServer) {
            Write-Verbose "Querying target server '$TargetServer' for local users"
            $TargetUsers = Get-NetLocalGroup $TargetServer -Recurse | Where-Object {(-not $_.IsGroup) -and $_.IsDomain } | ForEach-Object {
                $User = New-Object PSObject
                $User | Add-Member Noteproperty 'MemberDomain' ($_.AccountName).split("/")[0].toLower() 
                $User | Add-Member Noteproperty 'MemberName' ($_.AccountName).split("/")[1].toLower() 
                $User
            }  | Where-Object {$_}
        }
        # if we get a specific username, only use that
        elseif($UserName) {
            Write-Verbose "[*] Using target user '$UserName'..."
            $User = New-Object PSObject
            if($TargetDomains) {
                $User | Add-Member Noteproperty 'MemberDomain' $TargetDomains[0]
            }
            else {
                $User | Add-Member Noteproperty 'MemberDomain' $Null
            }
            $User | Add-Member Noteproperty 'MemberName' $UserName.ToLower()
            $TargetUsers = @($User)
        }
        # read in a target user list if we have one
        elseif($UserFile) {
            $TargetUsers = Get-Content -Path $UserFile | ForEach-Object {
                $User = New-Object PSObject
                if($TargetDomains) {
                    $User | Add-Member Noteproperty 'MemberDomain' $TargetDomains[0]
                }
                else {
                    $User | Add-Member Noteproperty 'MemberDomain' $Null
                }
                $User | Add-Member Noteproperty 'MemberName' $_
                $User
            }  | Where-Object {$_}
        }
        elseif($UserADSpath -or $UserFilter -or $AdminCount) {
            ForEach ($Domain in $TargetDomains) {

                $Arguments = @{
                    'Domain' = $Domain
                    'DomainController' = $DomainController
                    'ADSpath' = $UserADSpath
                    'Filter' = $UserFilter
                    'AdminCount' = $AdminCount
                    'AllowDelegation' = $AllowDelegation
                }

                Write-Verbose "[*] Querying domain $Domain for users"
                $TargetUsers += Get-NetUser @Arguments | ForEach-Object {
                    $User = New-Object PSObject
                    $User | Add-Member Noteproperty 'MemberDomain' $Domain
                    $User | Add-Member Noteproperty 'MemberName' $_.samaccountname
                    $User
                }  | Where-Object {$_}

            }
        }
        else {
            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for users of group '$GroupName'"
                $TargetUsers += Get-NetGroupMember -GroupName $GroupName -Domain $Domain -DomainController $DomainController
            }
        }

        if (( (-not $ShowAll) -and (-not $ForeignUsers) ) -and ((!$TargetUsers) -or ($TargetUsers.Count -eq 0))) {
            throw "[!] No users found to search for!"
        }

        # script block that enumerates a server
        $HostEnumBlock = {
            param($ComputerName, $Ping, $TargetUsers, $CurrentUser, $Stealth, $DomainShortName, $Poll, $Delay, $Jitter)

            # optionally check if the server is up first
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                $Timer = [System.Diagnostics.Stopwatch]::StartNew()
                $RandNo = New-Object System.Random

                Do {
                    if(!$DomainShortName) {
                        # if we're not searching for foreign users, check session information
                        $Sessions = Get-NetSession -ComputerName $ComputerName
                        ForEach ($Session in $Sessions) {
                            $UserName = $Session.sesi10_username
                            $CName = $Session.sesi10_cname

                            if($CName -and $CName.StartsWith("\\")) {
                                $CName = $CName.TrimStart("\")
                            }

                            # make sure we have a result
                            if (($UserName) -and ($UserName.trim() -ne '') -and (!($UserName -match $CurrentUser))) {

                                $TargetUsers | Where-Object {$UserName -like $_.MemberName} | ForEach-Object {

                                    $IPAddress = @(Get-IPAddress -ComputerName $ComputerName)[0].IPAddress
                                    $FoundUser = New-Object PSObject
                                    $FoundUser | Add-Member Noteproperty 'UserDomain' $_.MemberDomain
                                    $FoundUser | Add-Member Noteproperty 'UserName' $UserName
                                    $FoundUser | Add-Member Noteproperty 'ComputerName' $ComputerName
                                    $FoundUser | Add-Member Noteproperty 'IPAddress' $IPAddress
                                    $FoundUser | Add-Member Noteproperty 'SessionFrom' $CName

                                    # Try to resolve the DNS hostname of $Cname
                                    try {
                                        $CNameDNSName = [System.Net.Dns]::GetHostEntry($CName) | Select-Object -ExpandProperty HostName
                                        $FoundUser | Add-Member NoteProperty 'SessionFromName' $CnameDNSName
                                    }
                                    catch {
                                        $FoundUser | Add-Member NoteProperty 'SessionFromName' $Null
                                    }

                                    # see if we're checking to see if we have local admin access on this machine
                                    if ($CheckAccess) {
                                        $Admin = Invoke-CheckLocalAdminAccess -ComputerName $CName
                                        $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Admin.IsAdmin
                                    }
                                    else {
                                        $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Null
                                    }
                                    $FoundUser.PSObject.TypeNames.Add('PowerView.UserSession')
                                    $FoundUser
                                }
                            }
                        }
                    }
                    if(!$Stealth) {
                        # if we're not 'stealthy', enumerate loggedon users as well
                        $LoggedOn = Get-NetLoggedon -ComputerName $ComputerName
                        ForEach ($User in $LoggedOn) {
                            $UserName = $User.wkui1_username
                            # TODO: translate domain to authoratative name
                            #   then match domain name ?
                            $UserDomain = $User.wkui1_logon_domain

                            # make sure wet have a result
                            if (($UserName) -and ($UserName.trim() -ne '')) {

                                $TargetUsers | Where-Object {$UserName -like $_.MemberName} | ForEach-Object {

                                    $Proceed = $True
                                    if($DomainShortName) {
                                        if ($DomainShortName.ToLower() -ne $UserDomain.ToLower()) {
                                            $Proceed = $True
                                        }
                                        else {
                                            $Proceed = $False
                                        }
                                    }
                                    if($Proceed) {
                                        $IPAddress = @(Get-IPAddress -ComputerName $ComputerName)[0].IPAddress
                                        $FoundUser = New-Object PSObject
                                        $FoundUser | Add-Member Noteproperty 'UserDomain' $UserDomain
                                        $FoundUser | Add-Member Noteproperty 'UserName' $UserName
                                        $FoundUser | Add-Member Noteproperty 'ComputerName' $ComputerName
                                        $FoundUser | Add-Member Noteproperty 'IPAddress' $IPAddress
                                        $FoundUser | Add-Member Noteproperty 'SessionFrom' $Null
                                        $FoundUser | Add-Member Noteproperty 'SessionFromName' $Null

                                        # see if we're checking to see if we have local admin access on this machine
                                        if ($CheckAccess) {
                                            $Admin = Invoke-CheckLocalAdminAccess -ComputerName $ComputerName
                                            $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Admin.IsAdmin
                                        }
                                        else {
                                            $FoundUser | Add-Member Noteproperty 'LocalAdmin' $Null
                                        }
                                        $FoundUser.PSObject.TypeNames.Add('PowerView.UserSession')
                                        $FoundUser
                                    }
                                }
                            }
                        }
                    }

                    if ($Poll -gt 0) {
                        Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)
                    }
                } While ($Poll -gt 0 -and $Timer.Elapsed.TotalSeconds -lt $Poll)
            }
        }
    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            # if we're using threading, kick off the script block with Invoke-ThreadedFunction
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'TargetUsers' = $TargetUsers
                'CurrentUser' = $CurrentUser
                'Stealth' = $Stealth
                'DomainShortName' = $DomainShortName
                'Poll' = $Poll
                'Delay' = $Delay
                'Jitter' = $Jitter
            }

            # kick off the threaded script block + arguments 
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
            $RandNo = New-Object System.Random

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                # sleep for our semi-randomized interval
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                $Result = Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False, $TargetUsers, $CurrentUser, $Stealth, $DomainShortName, 0, 0, 0
                $Result

                if($Result -and $StopOnSuccess) {
                    Write-Verbose "[*] Target user found, returning early"
                    return
                }
            }
        }

    }
}