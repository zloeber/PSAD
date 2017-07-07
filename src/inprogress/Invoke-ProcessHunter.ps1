function Invoke-ProcessHunter {
<#
.SYNOPSIS
Query the process lists of remote machines, searching for
processes with a specific name or owned by a specific user.

.DESCRIPTION
Query the process lists of remote machines, searching for
processes with a specific name or owned by a specific user.

.PARAMETER ComputerName
Host array to enumerate, passable on the pipeline.

.PARAMETER ComputerFile
File of hostnames/IPs to search.

.PARAMETER ComputerFilter
Host filter name to query AD for, wildcards accepted.

.PARAMETER ComputerADSpath
The LDAP source to search through for hosts, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER ProcessName
The name of the process to hunt, or a comma separated list of names.

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

.PARAMETER StopOnSuccess
Switch. Stop hunting after finding after finding a target user/process.

.PARAMETER NoPing
Switch. Don't ping each host to ensure it's up before enumerating.

.PARAMETER Delay
Delay between enumerating hosts, defaults to 0

.PARAMETER Jitter
Jitter for the host delay, defaults to +/- 0.3

.PARAMETER Domain
Domain for query for machines, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER ShowAll
Switch. Return all user location results.

.PARAMETER SearchForest
Switch. Search all domains in the forest for target users instead of just
a single domain.

.PARAMETER Threads
The maximum concurrent threads to execute.

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target machine/domain.

.EXAMPLE
PS C:\> Invoke-ProcessHunter -Domain 'testing'

Finds machines on the 'testing' domain where domain admins have a
running process.

.EXAMPLE
PS C:\> Invoke-ProcessHunter -Threads 20

Multi-threaded process hunting, replaces Invoke-ProcessHunterThreaded.

.EXAMPLE
PS C:\> Invoke-ProcessHunter -UserFile users.txt -ComputerFile hosts.txt

Finds machines in hosts.txt where any members of users.txt have running
processes.

.EXAMPLE
PS C:\> Invoke-ProcessHunter -GroupName "Power Users" -Delay 60

Find machines on the domain where members of the "Power Users" groups have
running processes with a 60 second (+/- *.3) randomized delay between
touching each host.

.NOTES
Thanks to @paulbrandau for the approach idea.
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

        [String]
        $ProcessName,

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

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Management.Automation.PSCredential]
        $Credential
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        # random object for delay
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-ProcessHunter with delay of $Delay"

        #####################################################
        #
        # First we build the host target set
        #
        #####################################################

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
                $TargetDomains = Get-NetForestDomain -DomainController $DomainController -Credential $Credential | ForEach-Object { $_.Name }
            }
            else {
                # use the local domain
                $TargetDomains = @( (Get-NetDomain -Domain $Domain -Credential $Credential).name )
            }

            ForEach ($Domain in $TargetDomains) {
                Write-Verbose "[*] Querying domain $Domain for hosts"
                $ComputerName += Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -Filter $ComputerFilter -ADSpath $ComputerADSpath
            }
        
            # remove any null target hosts, uniquify the list and shuffle it
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.Count) -eq 0) {
                throw "No hosts found!"
            }
        }

        #####################################################
        #
        # Now we build the user target set
        #
        #####################################################

        if(!$ProcessName) {
            Write-Verbose "No process name specified, building a target user set"

            # users we're going to be searching for
            $TargetUsers = @()

            # if we want to hunt for the effective domain users who can access a target server
            if($TargetServer) {
                Write-Verbose "Querying target server '$TargetServer' for local users"
                $TargetUsers = Get-NetLocalGroup $TargetServer -Recurse | Where-Object {(-not $_.IsGroup) -and $_.IsDomain } | ForEach-Object {
                    ($_.AccountName).split("/")[1].toLower()
                }  | Where-Object {$_}
            }
            # if we get a specific username, only use that
            elseif($UserName) {
                Write-Verbose "[*] Using target user '$UserName'..."
                $TargetUsers = @( $UserName.ToLower() )
            }
            # read in a target user list if we have one
            elseif($UserFile) {
                $TargetUsers = Get-Content -Path $UserFile | Where-Object {$_}
            }
            elseif($UserADSpath -or $UserFilter) {
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for users"
                    $TargetUsers += Get-NetUser -Domain $Domain -DomainController $DomainController -Credential $Credential -ADSpath $UserADSpath -Filter $UserFilter | ForEach-Object {
                        $_.samaccountname
                    }  | Where-Object {$_}
                }
            }
            else {
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for users of group '$GroupName'"
                    $TargetUsers += Get-NetGroupMember -GroupName $GroupName -Domain $Domain -DomainController $DomainController -Credential $Credential| ForEach-Object {
                        $_.MemberName
                    }
                }
            }

            if ((-not $ShowAll) -and ((!$TargetUsers) -or ($TargetUsers.Count -eq 0))) {
                throw "[!] No users found to search for!"
            }
        }

        # script block that enumerates a server
        $HostEnumBlock = {
            param($ComputerName, $Ping, $ProcessName, $TargetUsers, $Credential)

            # optionally check if the server is up first
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                # try to enumerate all active processes on the remote host
                # and search for a specific process name
                $Processes = Get-NetProcess -Credential $Credential -ComputerName $ComputerName -ErrorAction SilentlyContinue

                ForEach ($Process in $Processes) {
                    # if we're hunting for a process name or comma-separated names
                    if($ProcessName) {
                        $ProcessName.split(",") | ForEach-Object {
                            if ($Process.ProcessName -match $_) {
                                $Process
                            }
                        }
                    }
                    # if the session user is in the target list, display some output
                    elseif ($TargetUsers -contains $Process.User) {
                        $Process
                    }
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
                'ProcessName' = $ProcessName
                'TargetUsers' = $TargetUsers
                'Credential' = $Credential
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

            ForEach ($Computer in $ComputerName) {

                $Counter = $Counter + 1

                # sleep for our semi-randomized interval
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $Computer ($Counter of $($ComputerName.count))"
                $Result = Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False, $ProcessName, $TargetUsers, $Credential
                $Result

                if($Result -and $StopOnSuccess) {
                    Write-Verbose "[*] Target user/process found, returning early"
                    return
                }
            }
        }
    }
}