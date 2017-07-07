Function Convert-ArrayToGuid ([System.Array]$byteArr) {
    $guidAsString = ''
    [int]$pos = 0
    $byteArr | ForEach-Object {
        $pos += 1
        if ($pos -in (5,7,9,11)) { 
            $guidAsString += '-'
        }
        $guidAsString += $_.ToString('x2').ToUpper()
    }
    [System.Guid]::Parse($guidAsString)
}
