function Invoke-EventHunter {
<#
.SYNOPSIS
Queries all domain controllers on the network for account
logon events (ID 4624) and TGT request events (ID 4768),
searching for target users.

.DESCRIPTION
Queries all domain controllers on the network for account
logon events (ID 4624) and TGT request events (ID 4768),
searching for target users.

Note: Domain Admin (or equiv) rights are needed to query
this information from the DCs.

.PARAMETER ComputerName

Host array to enumerate, passable on the pipeline.

.PARAMETER ComputerFile

File of hostnames/IPs to search.

.PARAMETER ComputerFilter

Host filter name to query AD for, wildcards accepted.

.PARAMETER ComputerADSpath

The LDAP source to search through for hosts, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

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

.PARAMETER NoPing

Don't ping each host to ensure it's up before enumerating.

.PARAMETER Domain

Domain for query for machines, defaults to the current domain.

.PARAMETER DomainController

Domain controller to reflect LDAP queries through.

.PARAMETER SearchDays

Number of days back to search logs for. Default 3.

.PARAMETER SearchForest

Switch. Search all domains in the forest for target users instead of just
a single domain.

.PARAMETER Threads

The maximum concurrent threads to execute.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

PS C:\> Invoke-EventHunter

.LINK

http://blog.harmj0y.net

.NOTES
Author: @sixdub, @harmj0y
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

        [String]
        $GroupName = 'Domain Admins',

        [String]
        $TargetServer,

        [String[]]
        $UserName,

        [String]
        $UserFilter,

        [String]
        $UserADSpath,

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $UserFile,

        [String]
        $Domain,

        [String]
        $DomainController,

        [Int32]
        $SearchDays = 3,

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

        Write-Verbose "[*] Running Invoke-EventHunter"

        if($Domain) {
            $TargetDomains = @($Domain)
        }
        elseif($SearchForest) {
            # get ALL the domains in the forest to search
            $TargetDomains = Get-NetForestDomain | ForEach-Object { $_.Name }
        }
        else {
            # use the local domain
            $TargetDomains = @( (Get-NetDomain -Credential $Credential).name )
        }

        #####################################################
        #
        # First we build the host target set
        #
        #####################################################

        if(!$ComputerName) { 
            # if we're using a host list, read the targets in and add them to the target list
            if($ComputerFile) {
                $ComputerName = Get-Content -Path $ComputerFile
            }
            elseif($ComputerFilter -or $ComputerADSpath) {
                [array]$ComputerName = @()
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for hosts"
                    $ComputerName += Get-NetComputer -Domain $Domain -DomainController $DomainController -Credential $Credential -Filter $ComputerFilter -ADSpath $ComputerADSpath
                }
            }
            else {
                # if a computer specifier isn't given, try to enumerate all domain controllers
                [array]$ComputerName = @()
                ForEach ($Domain in $TargetDomains) {
                    Write-Verbose "[*] Querying domain $Domain for domain controllers"
                    $ComputerName += Get-NetDomainController -LDAP -Domain $Domain -DomainController $DomainController -Credential $Credential | ForEach-Object { $_.dnshostname}
                }
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
            # Write-Verbose "[*] Using target user '$UserName'..."
            $TargetUsers = $UserName | ForEach-Object {$_.ToLower()}
            if($TargetUsers -isnot [System.Array]) {
                $TargetUsers = @($TargetUsers)
            }
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
                $TargetUsers += Get-NetGroupMember -GroupName $GroupName -Domain $Domain -DomainController $DomainController -Credential $Credential | ForEach-Object {
                    $_.MemberName
                }
            }
        }

        if (((!$TargetUsers) -or ($TargetUsers.Count -eq 0))) {
            throw "[!] No users found to search for!"
        }

        # script block that enumerates a server
        $HostEnumBlock = {
            param($ComputerName, $Ping, $TargetUsers, $SearchDays, $Credential)

            # optionally check if the server is up first
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                # try to enumerate
                if($Credential) {
                    Get-UserEvent -ComputerName $ComputerName -Credential $Credential -EventType 'all' -DateStart ([DateTime]::Today.AddDays(-$SearchDays)) | Where-Object {
                        # filter for the target user set
                        $TargetUsers -contains $_.UserName
                    }
                }
                else {
                    Get-UserEvent -ComputerName $ComputerName -EventType 'all' -DateStart ([DateTime]::Today.AddDays(-$SearchDays)) | Where-Object {
                        # filter for the target user set
                        $TargetUsers -contains $_.UserName
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
                'TargetUsers' = $TargetUsers
                'SearchDays' = $SearchDays
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
                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $(-not $NoPing), $TargetUsers, $SearchDays, $Credential
            }
        }

    }
}