Function Convert-DSName {
    <#
    .SYNOPSIS
    Translates Active Directory names between various formats.

    .DESCRIPTION
    Translates Active Directory names between various formats using the NameTranslate COM object. Before names can be translated, the NameTranslate object must first be initialized. The default initialization type is 'GC' (see the -InitType parameter). You can use the -Credential parameter to initialize the NameTranslate object using specific credentials.

    .PARAMETER OutputType
    The output name type, which must be one of the following:
    1779              RFC 1779; e.g., 'CN=Phineas Flynn,OU=Engineers,DC=fabrikam,DC=com'
    DN                short for 'distinguished name'; same as 1779
    canonical         canonical name; e.g., 'fabrikam.com/Engineers/Phineas Flynn'
    NT4               domain\username; e.g., 'fabrikam\pflynn'
    display           display name
    domainSimple      simple domain name format
    enterpriseSimple  simple enterprise name format
    GUID              GUID; e.g., '{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}'
    UPN               user principal name; e.g., 'pflynn@fabrikam.com'
    canonicalEx       extended canonical name format
    SPN               service principal name format

    .PARAMETER Name
    The name to translate. This parameter does not support wildcards.

    .PARAMETER InputType
    The input name type. Possible values are the same as -OutputType, with the following additions:
    unknown          unknown name format; the system will estimate the format
    SIDorSIDhistory  SDDL string for the SID or one from the object's SID history
    The default value for this parameter is 'unknown'.

    .PARAMETER InitType
    The type of initialization to be performed, which must be one of the following:
    domain  Bind to the domain specified by the -InitName parameter
    server  Bind to the server specified by the -InitName parameter
    GC      Locate and bind to a global catalog
    The default value for this parameter is 'GC'. When -InitType is not 'GC', you must also specify the -InitName parameter.

    .PARAMETER InitName
    When -InitType is 'domain' or 'server', this parameter specifies which domain or server to bind to. This parameter is ignored if -InitType is 'GC'.

    .PARAMETER ChaseReferrals
    This parameter specifies whether to chase referrals. (When a server determines that other servers hold relevant data, in part or as a whole, it may refer the client to another server to obtain the result. Referral chasing is the action taken by a client to contact the referred-to server to continue the directory search.)

    .PARAMETER Credential
    Uses the specified credentials when initializing the NameTranslate object.

    .EXAMPLE
    PS C:\> Convert-DSName -OutputType dn -Name fabrikam\pflynn
    This command outputs the specified domain\username as a distinguished name.

    PS C:\> Convert-DSName canonical 'CN=Phineas Flynn,OU=Engineers,DC=fabrikam,DC=com'
    This command outputs the specified DN as a canonical name.

    PS C:\> Convert-DSName dn fabrikam\pflynn -InitType server -InitName dc1
    This command uses the server dc1 to translate the specified name.

    PS C:\> Convert-DSName display fabrikam\pflynn -InitType domain -InitName fabrikam
    This command uses the fabrikam domain to translate the specified name.

    PS C:\> Convert-DSName dn 'fabrikam.com/Engineers/Phineas Flynn' -Credential (Get-Credential)
    Prompts for credentials, then uses those credentials to translate the specified name.

    PS C:\> Get-Content DNs.txt | Convert-DSName -OutputType display -InputType dn
    Outputs the display names for each of the distinguished names in the file DNs.txt.
    .NOTES
    Written by Bill Stewart (bstewart@iname.com)
    PowerShell wrapper script for the NameTranslate COM object.
    http://windowsitpro.com/active-directory/translating-active-directory-object-names-between-formats
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$TRUE,Position=0)]
        [String] $OutputType,
        [parameter(Mandatory=$TRUE,Position=1,ValueFromPipeline=$TRUE)]
        [String[]]$Name,
        [String]$InputType="unknown",
        [String]$InitType="GC",
        [String]$InitName="",
        [Switch]$ChaseReferrals,
        [Parameter(HelpMessage='Credentials to connect with.' )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        # Is input coming from the pipeline (-Name parameter not bound)?
        $PIPELINEINPUT = -not $PSBOUNDPARAMETERS.ContainsKey("Name")

        # Hash table to simplify output type names and values
        $OutputNameTypes = @{
            "1779"             = 1;
            "DN"               = 1;
            "canonical"        = 2;
            "NT4"              = 3;
            "display"          = 4;
            "domainSimple"     = 5;
            "enterpriseSimple" = 6;
            "GUID"             = 7;
            "UPN"              = 9;
            "canonicalEx"      = 10;
            "SPN"              = 11;
        }
        # Collect list of output types, and throw an error if -OutputType not in the list
        $OutputTypeNames = $OutputNameTypes.Keys | sort-object | foreach-object { $_ }
            if ( $OutputTypeNames -notcontains $OutputType ) {
                write-error "The -OutputType parameter must be one of the following values: $OutputTypeNames" -category InvalidArgument
                exit
            }

        # Copy output type hash table and add two additional types
        $InputNameTypes = $OutputNameTypes.Clone()
        $InputNameTypes.Add("unknown", 8)
        $InputNameTypes.Add("SIDorSidHistory", 12)
        # Collect list of input types, and throw an error if -InputType not in the list
        $InputTypeNames = $InputNameTypes.Keys | sort-object | foreach-object { $_ }
        if ( $InputTypeNames -notcontains $InputType ) {
            write-error "The -InputType parameter must be one of the following values: $InputTypeNames" -category InvalidArgument
            exit
        }

        # Same as with previous hash tables...
        $InitNameTypes = @{
            "domain" = 1;
            "server" = 2;
            "GC"     = 3;
        }
        $InitTypeNames = $InitNameTypes.Keys | sort-object | foreach-object { $_ }
        if ( $InitTypeNames -notcontains $InitType ) {
            write-error "The -InitType parameter must be one of the following values: $InitTypeNames" -category InvalidArgument
            exit
        }
        if ( ($InitType -ne "GC") -and ($InitName -eq "") ) {
            write-error "The -InitName parameter cannot be empty." -category InvalidArgument
            exit
        }

        # Accessor functions to simplify calls to NameTranslate
            function invoke-method([__ComObject] $object, [String] $method, $parameters) {
                $output = $object.GetType().InvokeMember($method, "InvokeMethod", $NULL, $object, $parameters)
                if ( $output ) { $output }
            }
            function get-property([__ComObject] $object, [String] $property) {
                $object.GetType().InvokeMember($property, "GetProperty", $NULL, $object, $NULL)
            }
            function set-property([__ComObject] $object, [String] $property, $parameters) {
                [Void] $object.GetType().InvokeMember($property, "SetProperty", $NULL, $object, $parameters)
            }

        # Create the NameTranslate COM object
        $NameTranslate = new-object -comobject NameTranslate

        # If -Credential, use InitEx to initialize it; otherwise, use Init
        if ( $Credential ) {
            $networkCredential = $Credential.GetNetworkCredential()
            try {
            invoke-method $NameTranslate "InitEx" (
                $InitNameTypes[$InitType],
                $InitName,
                $networkCredential.UserName,
                $networkCredential.Domain,
                $networkCredential.Password
            )
            }
            catch [System.Management.Automation.MethodInvocationException] {
                write-error $_
                exit
            }
            finally {
                remove-variable networkCredential
            }
        }
        else {
            try {
                invoke-method $NameTranslate "Init" (
                    $InitNameTypes[$InitType],
                    $InitName
                )
            }
            catch [System.Management.Automation.MethodInvocationException] {
                write-error $_
                exit
            }
        }

        # If -ChaseReferrals, set the object's ChaseReferral property to 0x60
        if ( $ChaseReferrals ) {
            set-property $NameTranslate "ChaseReferral" (0x60)
        }

        # The NameTranslate object's Set method specifies the name to translate and
        # its input format, and the Get method returns the name in the output format
        function Convert-DSName2([String] $name, [Int] $inputType, [Int] $outputType) {
            try {
                invoke-method $NameTranslate "Set" ($inputType, $name)
                invoke-method $NameTranslate "Get" ($outputType)
            }
            catch [System.Management.Automation.MethodInvocationException] {
                write-error "'$name' - $($_.Exception.InnerException.Message)"
            }
        }
    }

    process {
    if ( $PIPELINEINPUT ) {
        Convert-DSName2 $_ $InputNameTypes[$InputType] $OutputNameTypes[$OutputType]
    }
    else {
        $Name | foreach-object {
        Convert-DSName2 $_ $InputNameTypes[$InputType] $OutputNameTypes[$OutputType]
        }
    }
    }
}
