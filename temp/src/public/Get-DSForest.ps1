function Get-DSForest {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.1/docs/Functions/Get-DSForest.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name','Forest','ForestName')]
        [string]$Identity = ($Script:CurrentForest).name,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [switch]$UpdateCurrent
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    Process {     
        $context = Get-DSDirectoryContext -ContextType 'Forest' -ContextName $Identity -ComputerName $ComputerName -Credential $Credential
        $ForestObject = [DirectoryServices.ActiveDirectory.Forest]::GetForest($context)
        $RootDN = "DC=$(($ForestObject.Name).replace('.',',DC='))"
        $DEObj = Get-DSDirectoryEntry -DistinguishedName $RootDN -ComputerName $ComputerName -Credential $Credential
        $Sid = (New-Object -TypeName System.Security.Principal.SecurityIdentifier($DEObj.objectSid.value,0)).value
        Add-Member -InputObject $ForestObject -MemberType NoteProperty -Name 'Sid' -Value $Sid

        $ForestSid = (New-Object System.Security.Principal.NTAccount($ForestObject.RootDomain,"krbtgt")).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $Parts = $ForestSid -Split "-"
        $ForestSid = $Parts[0..$($Parts.length-2)] -join "-"
        $ForestObject | Add-Member NoteProperty 'RootDomainSid' $ForestSid

        if ($UpdateCurrent) {
            $Script:CurrentForest = $ForestObject
        }
        else {
            $ForestObject
        }
    }
}

