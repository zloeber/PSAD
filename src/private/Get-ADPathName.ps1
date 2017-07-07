Function Get-ADPathName
{
    # Get-ADPathname
    # Written by Bill Stewart (bstewart@iname.com)
    # PowerShell wrapper script for the Pathname COM object.

    #requires -version 2

    <#
    .SYNOPSIS
    Outputs Active Directory path names in various formats.

    .DESCRIPTION
    Outputs Active Directory (AD) path names in various formats using the Pathname COM object. The Pathname COM object implements the ADSI IADSPathname interface (see RELATED LINKS). This is a more robust means of handling AD path names than string parsing because it supports escaping of special characters.

    .PARAMETER Path
    Specifies the AD path. For example: "CN=Ken Dyer,DC=fabrikam,DC=com". If using the Full type (see -Full parameter), include the server and/or provider; for example: "LDAP://CN=Ken Dyer,DC=fabrikam,DC=com" or "LDAP://server/CN=Key Dyer,DC=fabrikam,DC=com".

    .PARAMETER Type
    Specifies the type of the AD path. This parameter must be one of the following values: "DN" or "Full". If you specify "Full", include the provider and/or server. The default value for this parameter is "DN".

    .PARAMETER Format
    Specifies the format in which to output the AD path. This parameter must be one of the following values: "Windows", "WindowsNoServer", "WindowsDN", "WindowsParent", "X500", "X500NoServer", "X500DN", "X500Parent", "Server", "Provider", or "Leaf". The default value for this parameter is "X500DN" (i.e., the distinguished name of the user, without provider or server names). This parameter's values correspond to the ADS_FORMAT_ENUM enumeration's values (see RELATED LINKS for more information and examples).

    .PARAMETER Retrieve
    Outputs the AD path using the format specified by the -Format parameter. This parameter is optional.

    .PARAMETER AddLeafElement
    Adds the specified leaf element(s) to the AD path and outputs the new AD path(s) using the format specified by the -Format parameter.

    .PARAMETER RemoveLeafElement
    Removes the final leaf element from the AD path and outputs the new AD path(s) using the format specified by the -Format parameter.

    .PARAMETER GetElement
    Outputs the specified element from the AD path. The left-most element is numbered 0 (zero), the second is numbered 1 (one), and so forth.

    .PARAMETER GetNumElements
    Outputs the number of elements in the AD path.

    .PARAMETER Split
    Outputs a list of the elements in the AD path.

    .PARAMETER GetEscapedElement
    Outputs one or more AD name element(s) with escape ("\") characters inserted in the correct places.

    .PARAMETER EscapedMode
    Specifies how escape characters are displayed in the AD path. This parameter must be one of the following values: "Default", "On", "Off", or "OffEx". The default value for this parameter is "Default".

    .PARAMETER ValuesOnly
    Specifies how elements in a path are output. If this parameter is absent, path elements are output using both attributes and values (e.g., "CN=Ken Dyer"). If this parameter is present, path elements are output with values only (e.g., "Ken Dyer").

    .INPUTS
    Inputs are AD path strings.

    .OUTPUTS
    Outputs are AD path strings.

    .EXAMPLE
    PS C:\> Get-ADPathname "LDAP://CN=Ken Dyer,CN=Users,DC=fabrikam,DC=com" -Type Full -Retrieve -Format X500DN
    Outputs "CN=Ken Dyer,CN=Users,DC=fabrikam,DC=com". The -Type parameter indicates that the AD path contains a provider (LDAP), and -Retrieve retrieves the path without the provider. The -Retrieve and -Format parameters are optional.

    .EXAMPLE
    PS C:\> Get-ADPathname "CN=Ken Dyer,CN=Users,DC=fabrikam,DC=com" -RemoveLeafElement
    This command removes the last element from the AD path ("CN=Ken Dyer") and outputs "CN=Users,DC=fabrikam,DC=com".

    .EXAMPLE
    PS C:\> Get-ADPathname "CN=Jeff Smith,CN=H/R,DC=fabrikam,DC=com" -EscapedMode On
    This command escapes the needed characters in the AD path and outputs "CN=Jeff Smith,CN=H\/R,DC=fabrikam,DC=com".

    .EXAMPLE
    PS C:\> Get-ADPathname "CN=H/R,DC=fabrikam,DC=com" -AddLeafElement "CN=Jeff Smith"
    This command adds the leaf element to the AD path and outputs "CN=Jeff Smith,CN=H/R,DC=fabrikam,DC=com".

    .EXAMPLE
    PS C:\> Get-ADPathname "CN=Jeff Smith,CN=H/R,DC=fabrikam,DC=com" -RemoveLeafElement
    This command removes the last element from the AD path ("CN=Jeff Smith") and outputs "CN=H/R,DC=fabrikam,DC=com".

    .EXAMPLE
    PS C:\> Get-ADPathname "CN=Ken Dyer,CN=Users,DC=fabrikam,DC=com" -Split
    This command splits the AD path and outputs a list of the elements: "CN=Ken Dyer", "CN=Users", "DC=fabrikam", and "DC=com".

    .EXAMPLE
    PS C:\> Get-Content ADPaths.txt | Get-ADPathname -EscapedMode On
    This command outputs all of the AD paths listed in the file ADPaths.txt with the needed escape characters.

    .EXAMPLE
    PS C:\> Get-ADPathname "CN=Users,DC=fabrikam,DC=com" -GetElement 0 -ValuesOnly
    This command gets the left-most element from the path and outputs "Users". Without the -ValuesOnly parameter, this command will output "CN=Users".

    .EXAMPLE
    PS C:\> Get-ADPathname -GetEscapedElement "OU=H/R"
    This command inserts the needed escape characters and outputs "OU=H\/R".

    .LINK
    ADSI IADSPathname Interface - http://msdn.microsoft.com/en-us/library/windows/desktop/aa706070.aspx
    ADS_FORMAT_ENUM Enumeration - http://msdn.microsoft.com/en-us/library/windows/desktop/aa772261.aspx
    #>

    [CmdletBinding(DefaultParameterSetName="Retrieve")]
    param(
      [parameter(ParameterSetName="Retrieve",Position=0,ValueFromPipeline=$TRUE)]
      [parameter(ParameterSetName="AddLeafElement",Position=0,Mandatory=$TRUE)]
      [parameter(ParameterSetName="RemoveLeafElement",Position=0,Mandatory=$TRUE)]
      [parameter(ParameterSetName="GetElement",Position=0,Mandatory=$TRUE)]
      [parameter(ParameterSetName="GetNumElements",Position=0,Mandatory=$TRUE)]
      [parameter(ParameterSetName="Split",Position=0,Mandatory=$TRUE)]
        [String[]]
        $Path,
      [parameter(ParameterSetName="Retrieve")]
      [parameter(ParameterSetName="AddLeafElement")]
      [parameter(ParameterSetName="RemoveLeafElement")]
      [parameter(ParameterSetName="GetElement")]
      [parameter(ParameterSetName="GetNumElements")]
      [parameter(ParameterSetName="Split")]
        [String] [ValidateSet("DN","Full")]
        $Type,
      [parameter(ParameterSetName="Retrieve")]
        [Switch]
        $Retrieve,
      [parameter(ParameterSetName="AddLeafElement",Mandatory=$TRUE)]
        [String[]]
        $AddLeafElement,
      [parameter(ParameterSetName="GetElement",Mandatory=$TRUE)]
        [UInt32]
        $GetElement,
      [parameter(ParameterSetName="RemoveLeafElement",Mandatory=$TRUE)]
        [Switch]
        $RemoveLeafElement,
      [parameter(ParameterSetName="GetNumElements",Mandatory=$TRUE)]
        [Switch]
        $GetNumElements,
      [parameter(ParameterSetName="Split",Mandatory=$TRUE)]
        [Switch]
        $Split,
      [parameter(ParameterSetName="Retrieve")]
      [parameter(ParameterSetName="AddLeafElement")]
      [parameter(ParameterSetName="RemoveLeafElement")]
        [String] [ValidateSet("Windows","WindowsNoServer","WindowsDN","WindowsParent","X500","X500NoServer","X500DN","X500Parent","Server","Provider","Leaf")]
        $Format,
      [parameter(ParameterSetName="Retrieve")]
      [parameter(ParameterSetName="AddLeafElement")]
      [parameter(ParameterSetName="RemoveLeafElement")]
      [parameter(ParameterSetName="GetElement")]
      [parameter(ParameterSetName="Split")]
        [String] [ValidateSet("Default","On","Off","OffEx")]
        $EscapedMode,
      [parameter(ParameterSetName="Retrieve")]
      [parameter(ParameterSetName="AddLeafElement")]
      [parameter(ParameterSetName="RemoveLeafElement")]
      [parameter(ParameterSetName="GetElement")]
      [parameter(ParameterSetName="Split")]
        [Switch]
        $ValuesOnly,
      [parameter(ParameterSetName="GetEscapedElement",Mandatory=$TRUE)]
        [String[]]
        $GetEscapedElement
    )

    begin {
      $ParamSetName = $PSCMDLET.ParameterSetName

      # Determine if we're using pipeline input.
      $PipelineInput = $FALSE
      if ( $ParamSetName -eq "Retrieve" ) {
        $PipelineInput = -not $PSBoundParameters.ContainsKey("Path")
      }

      # These hash tables improve code readability.
      $InputTypes = @{
        "Full" = 1
        "DN"   = 4
      }
      $OutputFormats = @{
        "Windows"         = 1 
        "WindowsNoServer" = 2 
        "WindowsDN"       = 3 
        "WindowsParent"   = 4 
        "X500"            = 5 
        "X500NoServer"    = 6 
        "X500DN"          = 7 
        "X500Parent"      = 8 
        "Server"          = 9 
        "Provider"        = 10
        "Leaf"            = 11
      }
      $EscapedModes = @{
        "Default" = 1
        "On"      = 2
        "Off"     = 3
        "OffEx"   = 4
      }
      $DisplayTypes = @{
        "Full"       = 1
        "ValuesOnly" = 2
      }

      # Invokes a method on a COM object that lacks a type library. If the COM
      # object uses more than one parameter, specify an array as the $parameters
      # parameter. The $outputType parameter coerces the function's output to the
      # specified type (default is [String]).
      function Invoke-Method {
        param(
          [__ComObject] $object,
          [String] $method,
          $parameters,
          [System.Type] $outputType = "String"
        )
        $output = $object.GetType().InvokeMember($method, "InvokeMethod", $NULL, $object, $parameters)
        if ( $output ) { $output -as $outputType }
      }

      # Sets a property on a COM object that lacks a type library.
      function Set-Property {
        param(
          [__ComObject] $object,
          [String] $property,
          $parameters
        )
        [Void] $object.GetType().InvokeMember($property, "SetProperty", $NULL, $object, $parameters)
      }

      # Creates the Pathname COM object. It lacks a type library so we use the
      # above Invoke-Method and Set-Property functions to interact with it.
      $Pathname = new-object -comobject "Pathname"

      # Set defaults for -Type and -Format. Use separate variables in case of
      # pipeline input.
      if ( $Type ) { $InputType = $Type } else { $InputType = "DN" }
      if ( $Format ) { $OutputFormat = $Format } else { $OutputFormat = "X500DN" }
      # Enable escaped mode if requested.
      if ( $EscapedMode ) {
        Set-Property $Pathname "EscapedMode" $EscapedModes[$EscapedMode]
      }
      # Output values only if requested.
      if ( $ValuesOnly ) {
        Invoke-Method $Pathname "SetDisplayType" $DisplayTypes["ValuesOnly"]
      }

      # -Retrieve parameter
      function Get-ADPathname-Retrieve {
        param(
          [String] $path,
          [Int] $inputType,
          [Int] $outputFormat
        )
        try {
          Invoke-Method $Pathname "Set" ($path,$inputType)
          Invoke-Method $Pathname "Retrieve" $outputFormat
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }

      # -AddLeafElement parameter
      function Get-ADPathname-AddLeafElement {
        param(
          [String] $path,
          [Int] $inputType,
          [String] $element,
          [Int] $outputFormat
        )
        try {
          Invoke-Method $Pathname "Set" ($path,$inputType)
          Invoke-Method $Pathname "AddLeafElement" $element
          Invoke-Method $Pathname "Retrieve" $outputFormat
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }

      # -RemoveLeafElement parameter
      function Get-ADPathname-RemoveLeafElement {
        param(
          [String] $path,
          [Int] $inputType,
          [Int] $outputFormat
        )
        try {
          Invoke-Method $Pathname "Set" ($path,$inputType)
          Invoke-Method $Pathname "RemoveLeafElement"
          Invoke-Method $Pathname "Retrieve" $outputFormat
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }

      # -GetElement parameter
      function Get-ADPathname-GetElement {
        param(
          [String] $path,
          [Int] $inputType,
          [Int] $elementIndex
        )
        try {
          Invoke-Method $Pathname "Set" ($path,$inputType)
          Invoke-Method $Pathname "GetElement" $elementIndex
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }

      # -GetNumElements parameter
      function Get-ADPathname-GetNumElements {
        param(
          [String] $path,
          [Int] $inputType
        )
        try {
          Invoke-Method $Pathname "Set" ($path,$inputType)
          Invoke-Method $Pathname "GetNumElements" -outputtype "UInt32"
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }

      # -Split parameter
      function Get-ADPathname-Split {
        param(
          [String] $path,
          [Int] $inputType
        )
        try {
          Invoke-Method $Pathname "Set" ($path,$inputType)
          $numElements = Invoke-Method $Pathname "GetNumElements" -outputtype "UInt32"
          for ( $i = 0; $i -lt $numElements; $i++ ) {
            Invoke-Method $Pathname "GetElement" $i
          }
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }

      # -GetEscapedElement parameter
      function Get-ADPathname-GetEscapedElement {
        param(
          [String] $element
        )
        try {
          Invoke-Method $Pathname "GetEscapedElement" (0,$element)
        }
        catch [System.Management.Automation.MethodInvocationException] {
          write-error -exception $_.Exception.InnerException
        }
      }
    }

    process {
      # The process block uses 'if'/'elseif' instead of 'switch' because 'switch'
      # replaces '$_', and we need '$_' in case of pipeline input.

      # "Retrieve" is the only parameter set that that accepts pipeline input.
      if ( $ParamSetName -eq "Retrieve" ) {
        if ( $PipelineInput ) {
          if ( $_ ) {
            Get-ADPathname-Retrieve $_ $InputTypes[$InputType] $OutputFormats[$OutputFormat]
          }
          else {
            write-error "You must provide pipeline input or specify the -Path parameter." -category SyntaxError
          }
        }
        else {
          $Path | foreach-object {
            Get-ADPathname-Retrieve $_ $InputTypes[$InputType] $OutputFormats[$OutputFormat]
          }
        }
      }
      elseif ( $ParamSetName -eq "AddLeafElement" ) {
        $AddLeafElement | foreach-object {
          Get-ADPathname-AddLeafElement $Path[0] $InputTypes[$InputType] $_ $OutputFormats[$OutputFormat]
        }
      }
      elseif ( $ParamSetName -eq "RemoveLeafElement" ) {
        $Path | foreach-object {
          Get-ADPathname-RemoveLeafElement $_ $InputTypes[$InputType] $OutputFormats[$OutputFormat]
        }
      }
      elseif ( $ParamSetName -eq "GetElement" ) {
        $Path | foreach-object {
          Get-ADPathname-GetElement $_ $InputTypes[$InputType] $GetElement
        }
      }
      elseif ( $ParamSetName -eq "GetNumElements" ) {
        $Path | foreach-object {
          Get-ADPathname-GetNumElements $_ $InputTypes[$InputType]
        }
      }
      elseif ( $ParamSetName -eq "Split" ) {
        Get-ADPathname-Split $Path[0] $InputTypes[$InputType]
      }
      elseif ( $ParamSetName -eq "GetEscapedElement" ) {
        $GetEscapedElement | foreach-object {
          Get-ADPathname-GetEscapedElement $_
        }
      }
    }
}
