function Convert-DNSRecord {
<#
    .SYNOPSIS
    Decodes a binary DNS record.
    .DESCRIPTION
    Decodes a binary DNS record.
    .PARAMETER DNSRecord
    The domain to query for zones, defaults to the current domain.
    .NOTES
    Adapted/ported from Michael B. Smith's code at https://raw.githubusercontent.com/mmessano/PowerShell/master/dns-dump.ps1
    .EXAMPLE
    TBD
    .LINK
    https://raw.githubusercontent.com/mmessano/PowerShell/master/dns-dump.ps1
#>
    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
        [Byte[]]
        $DNSRecord
    )

    function Get-Name {
        # modified decodeName from https://raw.githubusercontent.com/mmessano/PowerShell/master/dns-dump.ps1
        [CmdletBinding()]
        param(
            [Byte[]]
            $Raw
        )

        [Int]$Length = $Raw[0]
        [Int]$Segments = $Raw[1]
        [Int]$Index =  2
        [String]$Name  = ""

        while ($Segments-- -gt 0)
        {
            [Int]$SegmentLength = $Raw[$Index++]
            while ($SegmentLength-- -gt 0) {
                $Name += [Char]$Raw[$Index++]
            }
            $Name += "."
        }
        $Name
    }

    $RDataLen = [BitConverter]::ToUInt16($DNSRecord, 0)
    $RDataType = [BitConverter]::ToUInt16($DNSRecord, 2)
    $UpdatedAtSerial = [BitConverter]::ToUInt32($DNSRecord, 8)

    $TTLRaw = $DNSRecord[12..15]
    # reverse for big endian
    $Null = [array]::Reverse($TTLRaw)
    $TTL = [BitConverter]::ToUInt32($TTLRaw, 0)

    $Age = [BitConverter]::ToUInt32($DNSRecord, 20)
    if($Age -ne 0) {
        $TimeStamp = ((Get-Date -Year 1601 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0).AddHours($age)).ToString()
    }
    else {
        $TimeStamp = "[static]"
    }

    $DNSRecordObject = New-Object PSObject

    if($RDataType -eq 1) {
        $IP = "{0}.{1}.{2}.{3}" -f $DNSRecord[24], $DNSRecord[25], $DNSRecord[26], $DNSRecord[27]
        $Data = $IP
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'A'
    }

    elseif($RDataType -eq 2) {
        $NSName = Get-Name $DNSRecord[24..$DNSRecord.length]
        $Data = $NSName
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'NS'
    }

    elseif($RDataType -eq 5) {
        $Alias = Get-Name $DNSRecord[24..$DNSRecord.length]
        $Data = $Alias
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'CNAME'
    }

    elseif($RDataType -eq 6) {
        # TODO: how to implement properly? nested object?
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'SOA'
    }

    elseif($RDataType -eq 12) {
        $Ptr = Get-Name $DNSRecord[24..$DNSRecord.length]
        $Data = $Ptr
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'PTR'
    }

    elseif($RDataType -eq 13) {
        # TODO: how to implement properly? nested object?
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'HINFO'
    }

    elseif($RDataType -eq 15) {
        # TODO: how to implement properly? nested object?
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'MX'
    }

    elseif($RDataType -eq 16) {

        [string]$TXT  = ""
        [int]$SegmentLength = $DNSRecord[24]
        $Index = 25
        while ($SegmentLength-- -gt 0) {
            $TXT += [char]$DNSRecord[$index++]
        }

        $Data = $TXT
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'TXT'
    }

    elseif($RDataType -eq 28) {
        # TODO: how to implement properly? nested object?
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'AAAA'
    }

    elseif($RDataType -eq 33) {
        # TODO: how to implement properly? nested object?
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'SRV'
    }

    else {
        $Data = $([System.Convert]::ToBase64String($DNSRecord[24..$DNSRecord.length]))
        $DNSRecordObject | Add-Member Noteproperty 'RecordType' 'UNKNOWN'
    }

    $DNSRecordObject | Add-Member Noteproperty 'UpdatedAtSerial' $UpdatedAtSerial
    $DNSRecordObject | Add-Member Noteproperty 'TTL' $TTL
    $DNSRecordObject | Add-Member Noteproperty 'Age' $Age
    $DNSRecordObject | Add-Member Noteproperty 'TimeStamp' $TimeStamp
    $DNSRecordObject | Add-Member Noteproperty 'Data' $Data
    $DNSRecordObject
}