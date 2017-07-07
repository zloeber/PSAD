function Invoke-FileFinder {
<#
.SYNOPSIS
Finds sensitive files on the domain.

.DESCRIPTION
This function finds the local domain name for a host using Get-NetDomain,
queries the domain for all active machines with Get-NetComputer, grabs
the readable shares for each server, and recursively searches every
share for files with specific keywords in the name.
If a share list is passed, EVERY share is enumerated regardless of
other options.

.PARAMETER ComputerName

Host array to enumerate, passable on the pipeline.

.PARAMETER ComputerFile

File of hostnames/IPs to search.

.PARAMETER ComputerFilter

Host filter name to query AD for, wildcards accepted.

.PARAMETER ComputerADSpath

The LDAP source to search through for hosts, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
Useful for OU queries.

.PARAMETER ShareList

List if \\HOST\shares to search through.

.PARAMETER Terms
Terms to search for.

.PARAMETER SearchTerms
TBD.

.PARAMETER TermList
TBD

.PARAMETER OfficeDocs

Switch. Search for office documents (*.doc*, *.xls*, *.ppt*)

.PARAMETER FreshEXEs

Switch. Find .EXEs accessed within the last week.

.PARAMETER LastAccessTime

Only return files with a LastAccessTime greater than this date value.

.PARAMETER LastWriteTime

Only return files with a LastWriteTime greater than this date value.

.PARAMETER CreationTime

Only return files with a CreationDate greater than this date value.

.PARAMETER IncludeC

Switch. Include any C$ shares in recursive searching (default ignore).

.PARAMETER IncludeAdmin

Switch. Include any ADMIN$ shares in recursive searching (default ignore).

.PARAMETER ExcludeFolders

Switch. Exclude folders from the search results.

.PARAMETER ExcludeHidden

Switch. Exclude hidden files and folders from the search results.

.PARAMETER CheckWriteAccess

Switch. Only returns files the current user has write access to.

.PARAMETER OutFile

Output results to a specified csv output file.

.PARAMETER NoClobber

Switch. Don't overwrite any existing output file.

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

Search all domains in the forest for target users instead of just
a single domain.

.PARAMETER SearchSYSVOL

Switch. Search for login scripts on the SYSVOL of the primary DCs for each specified domain.

.PARAMETER Threads

The maximum concurrent threads to execute.

.PARAMETER UsePSDrive

Switch. Mount target remote path with temporary PSDrives.

.EXAMPLE

PS C:\> Invoke-FileFinder

Find readable files on the domain with 'pass', 'sensitive',
'secret', 'admin', 'login', or 'unattend*.xml' in the name,

.EXAMPLE

PS C:\> Invoke-FileFinder -Domain testing

Find readable files on the 'testing' domain with 'pass', 'sensitive',
'secret', 'admin', 'login', or 'unattend*.xml' in the name,

.EXAMPLE

PS C:\> Invoke-FileFinder -IncludeC

Find readable files on the domain with 'pass', 'sensitive',
'secret', 'admin', 'login' or 'unattend*.xml' in the name,
including C$ shares.

.EXAMPLE

PS C:\> Invoke-FileFinder -ShareList shares.txt -Terms accounts,ssn -OutFile out.csv

Enumerate a specified share list for files with 'accounts' or
'ssn' in the name, and write everything to "out.csv"

.NOTES
Author: @harmj0y
License: BSD 3-Clause

.LINK
http://www.harmj0y.net/blog/redteaming/file-server-triage-on-red-team-engagements/

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

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $ShareList,

        [Switch]
        $OfficeDocs,

        [Switch]
        $FreshEXEs,

        [Alias('Terms')]
        [String[]]
        $SearchTerms, 

        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $TermList,

        [String]
        $LastAccessTime,

        [String]
        $LastWriteTime,

        [String]
        $CreationTime,

        [Switch]
        $IncludeC,

        [Switch]
        $IncludeAdmin,

        [Switch]
        $ExcludeFolders,

        [Switch]
        $ExcludeHidden,

        [Switch]
        $CheckWriteAccess,

        [String]
        $OutFile,

        [Switch]
        $NoClobber,

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

        [Switch]
        $SearchSYSVOL,

        [ValidateRange(1,100)] 
        [Int]
        $Threads,

        [Switch]
        $UsePSDrive
    )

    begin {
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        # random object for delay
        $RandNo = New-Object System.Random

        Write-Verbose "[*] Running Invoke-FileFinder with delay of $Delay"

        $Shares = @()

        # figure out the shares we want to ignore
        [String[]] $ExcludedShares = @("C$", "ADMIN$")

        # see if we're specifically including any of the normally excluded sets
        if ($IncludeC) {
            if ($IncludeAdmin) {
                $ExcludedShares = @()
            }
            else {
                $ExcludedShares = @("ADMIN$")
            }
        }

        if ($IncludeAdmin) {
            if ($IncludeC) {
                $ExcludedShares = @()
            }
            else {
                $ExcludedShares = @("C$")
            }
        }

        # delete any existing output file if it already exists
        if(!$NoClobber) {
            if ($OutFile -and (Test-Path -Path $OutFile)) { Remove-Item -Path $OutFile }
        }

        # if there's a set of terms specified to search for
        if ($TermList) {
            ForEach ($Term in Get-Content -Path $TermList) {
                if (($Term -ne $Null) -and ($Term.trim() -ne '')) {
                    $SearchTerms += $Term
                }
            }
        }

        # if we're hard-passed a set of shares
        if($ShareList) {
            ForEach ($Item in Get-Content -Path $ShareList) {
                if (($Item -ne $Null) -and ($Item.trim() -ne '')) {
                    # exclude any "[tab]- commants", i.e. the output from Invoke-ShareFinder
                    $Share = $Item.Split("`t")[0]
                    $Shares += $Share
                }
            }
        }
        else {
            # if we're using a host file list, read the targets in and add them to the target list
            if($ComputerFile) {
                $ComputerName = Get-Content -Path $ComputerFile
            }

            if(!$ComputerName) {

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

                if($SearchSYSVOL) {
                    ForEach ($Domain in $TargetDomains) {
                        $DCSearchPath = "\\$Domain\SYSVOL\"
                        Write-Verbose "[*] Adding share search path $DCSearchPath"
                        $Shares += $DCSearchPath
                    }
                    if(!$SearchTerms) {
                        # search for interesting scripts on SYSVOL
                        $SearchTerms = @('.vbs', '.bat', '.ps1')
                    }
                }
                else {
                    [array]$ComputerName = @()

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
            }
        }

        # script block that enumerates shares and files on a server
        $HostEnumBlock = {
            param($ComputerName, $Ping, $ExcludedShares, $SearchTerms, $ExcludeFolders, $OfficeDocs, $ExcludeHidden, $FreshEXEs, $CheckWriteAccess, $OutFile, $UsePSDrive)

            Write-Verbose "ComputerName: $ComputerName"
            Write-Verbose "ExcludedShares: $ExcludedShares"
            $SearchShares = @()

            if($ComputerName.StartsWith("\\")) {
                # if a share is passed as the server
                $SearchShares += $ComputerName
            }
            else {
                # if we're enumerating the shares on the target server first
                $Up = $True
                if($Ping) {
                    $Up = Test-Connection -Count 1 -Quiet -ComputerName $ComputerName
                }
                if($Up) {
                    # get the shares for this host and display what we find
                    $Shares = Get-NetShare -ComputerName $ComputerName
                    ForEach ($Share in $Shares) {

                        $NetName = $Share.shi1_netname
                        $Path = '\\'+$ComputerName+'\'+$NetName

                        # make sure we get a real share name back
                        if (($NetName) -and ($NetName.trim() -ne '')) {

                            # skip this share if it's in the exclude list
                            if ($ExcludedShares -NotContains $NetName.ToUpper()) {
                                # check if the user has access to this path
                                try {
                                    $Null = [IO.Directory]::GetFiles($Path)
                                    $SearchShares += $Path
                                }
                                catch {
                                    Write-Verbose "[!] No access to $Path"
                                }
                            }
                        }
                    }
                }
            }

            ForEach($Share in $SearchShares) {
                $SearchArgs =  @{
                    'Path' = $Share
                    'SearchTerms' = $SearchTerms
                    'OfficeDocs' = $OfficeDocs
                    'FreshEXEs' = $FreshEXEs
                    'LastAccessTime' = $LastAccessTime
                    'LastWriteTime' = $LastWriteTime
                    'CreationTime' = $CreationTime
                    'ExcludeFolders' = $ExcludeFolders
                    'ExcludeHidden' = $ExcludeHidden
                    'CheckWriteAccess' = $CheckWriteAccess
                    'OutFile' = $OutFile
                    'UsePSDrive' = $UsePSDrive
                }

                Find-InterestingFile @SearchArgs
            }
        }
    }

    process {

        if($Threads) {
            Write-Verbose "Using threading with threads = $Threads"

            # if we're using threading, kick off the script block with Invoke-ThreadedFunction
            $ScriptParams = @{
                'Ping' = $(-not $NoPing)
                'ExcludedShares' = $ExcludedShares
                'SearchTerms' = $SearchTerms
                'ExcludeFolders' = $ExcludeFolders
                'OfficeDocs' = $OfficeDocs
                'ExcludeHidden' = $ExcludeHidden
                'FreshEXEs' = $FreshEXEs
                'CheckWriteAccess' = $CheckWriteAccess
                'OutFile' = $OutFile
                'UsePSDrive' = $UsePSDrive
            }

            # kick off the threaded script block + arguments 
            if($Shares) {
                # pass the shares as the hosts so the threaded function code doesn't have to be hacked up
                Invoke-ThreadedFunction -ComputerName $Shares -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
            }
            else {
                Invoke-ThreadedFunction -ComputerName $ComputerName -ScriptBlock $HostEnumBlock -ScriptParameters $ScriptParams -Threads $Threads
            }
        }

        else {
            if($Shares){
                $ComputerName = $Shares
            }
            elseif(-not $NoPing -and ($ComputerName.count -gt 1)) {
                # ping all hosts in parallel
                $Ping = {param($ComputerName) if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop){$ComputerName}}
                $ComputerName = Invoke-ThreadedFunction -NoImports -ComputerName $ComputerName -ScriptBlock $Ping -Threads 100
            }

            Write-Verbose "[*] Total number of active hosts: $($ComputerName.count)"
            $Counter = 0

            $ComputerName | Where-Object {$_} | ForEach-Object {
                Write-Verbose "Computer: $_"
                $Counter = $Counter + 1

                # sleep for our semi-randomized interval
                Start-Sleep -Seconds $RandNo.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)

                Write-Verbose "[*] Enumerating server $_ ($Counter of $($ComputerName.count))"

                Invoke-Command -ScriptBlock $HostEnumBlock -ArgumentList $_, $False, $ExcludedShares, $SearchTerms, $ExcludeFolders, $OfficeDocs, $ExcludeHidden, $FreshEXEs, $CheckWriteAccess, $OutFile, $UsePSDrive                
            }
        }
    }
}