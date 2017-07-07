function Find-LocalAdminAccess {
<#
.SYNOPSIS
Finds machines on the local domain where the current user has local administrator access. Uses multithreading to speed up enumeration.

.DESCRIPTION
This function finds the local domain name for a host using Get-NetDomain,
queries the domain for all active machines with Get-NetComputer, then for
each server it checks if the current user has local administrator
access using Invoke-CheckLocalAdminAccess.

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

.PARAMETER Domain
Domain to query for machines, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER SearchForest
Switch. Search all domains in the forest for target users instead of just
a single domain.

.PARAMETER Threads
The maximum concurrent threads to execute.

.EXAMPLE
PS C:\> Find-LocalAdminAccess

Find machines on the local domain where the current user has local
administrator access.

.EXAMPLE
PS C:\> Find-LocalAdminAccess -Threads 10

Multi-threaded access hunting, replaces Find-LocalAdminAccessThreaded.

.EXAMPLE
PS C:\> Find-LocalAdminAccess -Domain testing

Find machines on the 'testing' domain where the current user has
local administrator access.

.EXAMPLE
PS C:\> Find-LocalAdminAccess -ComputerFile hosts.txt

Find which machines in the host list the current user has local
administrator access.

.NOTES
Idea stolen from the local_admin_search_enum post module in
Metasploit written by:
    'Brandon McCann "zeknox" <bmccann[at]accuvant.com>'
    'Thomas McCarthy "smilingraccoon" <smilingraccoon[at]gmail.com>'
    'Royce Davis "r3dy" <rdavis[at]accuvant.com>'

Author: @harmj0y
License: BSD 3-Clause

.LINK
https://github.com/rapid7/metasploit-framework/blob/master/modules/post/windows/gather/local_admin_search_enum.rb

.LINK
http://www.harmj0y.net/blog/penetesting/finding-local-admin-with-the-veil-framework/
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
        $Domain,

        [String]
        $DomainController,

        [Switch]
        $SearchForest,

        [ValidateRange(1,100)] 
        [Int]
        $Threads
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        # random object for delay
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Find-LocalAdminAccess with delay of $Delay"

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

        # script block that enumerates a server
        $HostEnumBlock = {
            param($ComputerName, $Ping)

            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                # check if the current user has local admin access to this server
                $Access = Invoke-CheckLocalAdminAccess -ComputerName $ComputerName
                if ($Access.IsAdmin) {
                    $ComputerName
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
                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False
            }
        }
    }
}