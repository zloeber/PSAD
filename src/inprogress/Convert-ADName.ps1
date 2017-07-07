function Convert-ADName {
<#
.SYNOPSIS
Converts user/group names from NT4 (DOMAIN\user) or domainSimple (user@domain.com)
to canonical format (domain.com/Users/user) or NT4.

.DESCRIPTION
Converts user/group names from NT4 (DOMAIN\user) or domainSimple (user@domain.com)
to canonical format (domain.com/Users/user) or NT4.

.PARAMETER ObjectName
The user/group name to convert.

.PARAMETER InputType
The InputType of the user/group name ("NT4","Simple","Canonical").

.PARAMETER OutputType
The OutputType of the user/group name ("NT4","Simple","Canonical").

.EXAMPLE
PS C:\> Convert-ADName -ObjectName "dev\dfm"

Returns "dev.testlab.local/Users/Dave"

.EXAMPLE
PS C:\> Convert-SidToName "S-..." | Convert-ADName

Returns the canonical name for the resolved SID.

.NOTES
Based on Bill Stewart's code from this article: 
http://windowsitpro.com/active-directory/translating-active-directory-object-names-between-formats

.LINK
http://windowsitpro.com/active-directory/translating-active-directory-object-names-between-formats
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $ObjectName,

        [String]
        [ValidateSet("NT4","Simple","Canonical")]
        $InputType,

        [String]
        [ValidateSet("NT4","Simple","Canonical")]
        $OutputType
    )

    $NameTypes = @{
        'Canonical' = 2
        'NT4'       = 3
        'Simple'    = 5
    }

    if(-not $PSBoundParameters['InputType']) {
        if( ($ObjectName.split('/')).Count -eq 2 ) {
            $ObjectName = $ObjectName.replace('/', '\')
        }

        if($ObjectName -match "^[A-Za-z]+\\[A-Za-z ]+") {
            $InputType = 'NT4'
        }
        elseif($ObjectName -match "^[A-Za-z ]+@[A-Za-z\.]+") {
            $InputType = 'Simple'
        }
        elseif($ObjectName -match "^[A-Za-z\.]+/[A-Za-z]+/[A-Za-z/ ]+") {
            $InputType = 'Canonical'
        }
        else {
            Write-Warning "Can not identify InType for $ObjectName"
            return $ObjectName
        }
    }
    elseif($InputType -eq 'NT4') {
        $ObjectName = $ObjectName.replace('/', '\')
    }

    if(-not $PSBoundParameters['OutputType']) {
        $OutputType = Switch($InputType) {
            'NT4' {'Canonical'}
            'Simple' {'NT4'}
            'Canonical' {'NT4'}
        }
    }

    # try to extract the domain from the given format
    $Domain = Switch($InputType) {
        'NT4' { $ObjectName.split("\")[0] }
        'Simple' { $ObjectName.split("@")[1] }
        'Canonical' { $ObjectName.split("/")[0] }
    }

    # Accessor functions to simplify calls to NameTranslate
    function Invoke-Method([__ComObject] $Object, [String] $Method, $Parameters) {
        $Output = $Object.GetType().InvokeMember($Method, "InvokeMethod", $Null, $Object, $Parameters)
        if ( $Output ) { $Output }
    }
    function Set-Property([__ComObject] $Object, [String] $Property, $Parameters) {
        [Void] $Object.GetType().InvokeMember($Property, "SetProperty", $Null, $Object, $Parameters)
    }

    $Translate = New-Object -ComObject NameTranslate

    try {
        Invoke-Method $Translate "Init" (1, $Domain)
    }
    catch [System.Management.Automation.MethodInvocationException] { 
        Write-Verbose "Error with translate init in Convert-ADName: $_"
    }

    Set-Property $Translate "ChaseReferral" (0x60)

    try {
        Invoke-Method $Translate "Set" ($NameTypes[$InputType], $ObjectName)
        (Invoke-Method $Translate "Get" ($NameTypes[$OutputType]))
    }
    catch [System.Management.Automation.MethodInvocationException] {
        Write-Verbose "Error with translate Set/Get in Convert-ADName: $_"
    }
}