function Invoke-ShareFinder {
<#
.SYNOPSIS
This function finds the local domain name for a host using Get-NetDomain,
queries the domain for all active machines with Get-NetComputer, then for
each server it lists of active shares with Get-NetShare. Non-standard shares
can be filtered out with -Exclude* flags.

.DESCRIPTION
This function finds the local domain name for a host using Get-NetDomain,
queries the domain for all active machines with Get-NetComputer, then for
each server it lists of active shares with Get-NetShare. Non-standard shares
can be filtered out with -Exclude* flags.

.PARAMETER ComputerName

Host array to enumerate, passable on the pipeline.

.PARAMETER ComputerFile

File of hostnames/IPs to search.

.PARAMETER ComputerFilter

Host filter name to query AD for, wildcards accepted.

.PARAMETER ComputerADSpath

The LDAP source to search through for hosts, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER ExcludeStandard

Switch. Exclude standard shares from display (C$, IPC$, print$ etc.)

.PARAMETER ExcludePrint

Switch. Exclude the print$ share.

.PARAMETER ExcludeIPC

Switch. Exclude the IPC$ share.

.PARAMETER CheckShareAccess

Switch. Only display found shares that the local user has access to.

.PARAMETER CheckAdmin

Switch. Only display ADMIN$ shares the local user has access to.

.PARAMETER NoPing

Switch. Don't ping each host to ensure it's up before enumerating.

.PARAMETER Delay

Delay between enumerating hosts, defaults to 0.

.PARAMETER Jitter

Jitter for the host delay, defaults to +/- 0.3.

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

PS C:\> Invoke-ShareFinder -ExcludeStandard

Find non-standard shares on the domain.

.EXAMPLE

PS C:\> Invoke-ShareFinder -Threads 20

Multi-threaded share finding, replaces Invoke-ShareFinderThreaded.

.EXAMPLE

PS C:\> Invoke-ShareFinder -Delay 60

Find shares on the domain with a 60 second (+/- *.3)
randomized delay between touching each host.

.EXAMPLE

PS C:\> Invoke-ShareFinder -ComputerFile hosts.txt

Find shares for machines in the specified hosts file.

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
        $ExcludeStandard,

        [Switch]
        $ExcludePrint,

        [Switch]
        $ExcludeIPC,

        [Switch]
        $NoPing,

        [Switch]
        $CheckShareAccess,

        [Switch]
        $CheckAdmin,

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

        Write-Verbose "[*] Running Invoke-ShareFinder with delay of $Delay"

        # figure out the shares we want to ignore
        [String[]] $ExcludedShares = @('')

        if ($ExcludePrint) {
            $ExcludedShares = $ExcludedShares + "PRINT$"
        }
        if ($ExcludeIPC) {
            $ExcludedShares = $ExcludedShares + "IPC$"
        }
        if ($ExcludeStandard) {
            $ExcludedShares = @('', "ADMIN$", "IPC$", "C$", "PRINT$")
        }

        # if we're using a host file list, read the targets in and add them to the target list
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
                $ComputerName += Get-NetComputer -Domain $Domain -DomainController $DomainController -Filter $ComputerFilter -ADSpath $ComputerADSpath
            }
        
            # remove any null target hosts, uniquify the list and shuffle it
            $ComputerName = $ComputerName | Where-Object { $_ } | Sort-Object -Unique | Sort-Object { Get-Random }
            if($($ComputerName.count) -eq 0) {
                throw "No hosts found!"
            }
        }

        # script block that enumerates a server
        $HostEnumBlock = {
            param($ComputerName, $Ping, $CheckShareAccess, $ExcludedShares, $CheckAdmin)

            # optionally check if the server is up first
            $Up = $True
            if($Ping) {
                $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
            }
            if($Up) {
                # get the shares for this host and check what we find
                $Shares = Get-NetShare -ComputerName $ComputerName
                ForEach ($Share in $Shares) {
                    Write-Verbose "[*] Server share: $Share"
                    $NetName = $Share.shi1_netname
                    $Remark = $Share.shi1_remark
                    $Path = '\\'+$ComputerName+'\'+$NetName

                    # make sure we get a real share name back
                    if (($NetName) -and ($NetName.trim() -ne '')) {
                        # if we're just checking for access to ADMIN$
                        if($CheckAdmin) {
                            if($NetName.ToUpper() -eq "ADMIN$") {
                                try {
                                    $Null = [IO.Directory]::GetFiles($Path)
                                    "\\$ComputerName\$NetName `t- $Remark"
                                }
                                catch {
                                    Write-Verbose "Error accessing path $Path : $_"
                                }
                            }
                        }
                        # skip this share if it's in the exclude list
                        elseif ($ExcludedShares -NotContains $NetName.ToUpper()) {
                            # see if we want to check access to this share
                            if($CheckShareAccess) {
                                # check if the user has access to this path
                                try {
                                    $Null = [IO.Directory]::GetFiles($Path)
                                    "\\$ComputerName\$NetName `t- $Remark"
                                }
                                catch {
                                    Write-Verbose "Error accessing path $Path : $_"
                                }
                            }
                            else {
                                "\\$ComputerName\$NetName `t- $Remark"
                            }
                        }
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
                'CheckShareAccess' = $CheckShareAccess
                'ExcludedShares' = $ExcludedShares
                'CheckAdmin' = $CheckAdmin
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
                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $Computer, $False, $CheckShareAccess, $ExcludedShares, $CheckAdmin
            }
        }
        
    }
}