filter Get-NameField {
    <#
    .SYNOPSIS
    Helper that attempts to extract appropriate field names from
    passed computer objects.

    .PARAMETER Object
    The passed object to extract name fields from.

    .PARAMETER DnsHostName
    A DnsHostName to extract through ValueFromPipelineByPropertyName.

    .PARAMETER Name
    A Name to extract through ValueFromPipelineByPropertyName.

    .EXAMPLE
    PS C:\> Get-NetComputer -FullData | Get-NameField
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Object]
        $Object,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $DnsHostName,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [String]
        $Name
    )

    if($PSBoundParameters['DnsHostName']) {
        $DnsHostName
    }
    elseif($PSBoundParameters['Name']) {
        $Name
    }
    elseif($Object) {
        if ( [bool]($Object.PSobject.Properties.name -match "dnshostname") ) {
            # objects from Get-NetComputer
            $Object.dnshostname
        }
        elseif ( [bool]($Object.PSobject.Properties.name -match "name") ) {
            # objects from Get-NetDomainController
            $Object.name
        }
        else {
            # strings and catch alls
            $Object
        }
    }
    else {
        return $Null
    }
}
