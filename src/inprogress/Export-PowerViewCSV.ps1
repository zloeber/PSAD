function Export-PowerViewCSV {
<#
.SYNOPSIS
This helper exports an -InputObject to a .csv in a thread-safe manner
using a mutex. This is so the various multi-threaded functions in
PowerView has a thread-safe way to export output to the same file.

.DESCRIPTION
This helper exports an -InputObject to a .csv in a thread-safe manner
using a mutex. This is so the various multi-threaded functions in
PowerView has a thread-safe way to export output to the same file.

.PARAMETER InputObject
Object to export to csv.

.PARAMETER OutFile
File to export csv entries to.

.NOTES
Based partially on Dmitry Sotnikov's Export-CSV code at http://poshcode.org/1590

.EXAMPLE
TBD

.LINK
http://poshcode.org/1590

.LINK
http://dmitrysotnikov.wordpress.com/2010/01/19/Export-Csv-append/
#>
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [System.Management.Automation.PSObject[]]$InputObject,

        [Parameter(Mandatory=$True, Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]$OutFile
    )

    $ObjectCSV = $InputObject | ConvertTo-Csv -NoTypeInformation

    # mutex so threaded code doesn't stomp on the output file
    $Mutex = New-Object System.Threading.Mutex $False,'CSVMutex';
    $Null = $Mutex.WaitOne()

    if (Test-Path -Path $OutFile) {
        # hack to skip the first line of output if the file already exists
        $ObjectCSV | ForEach-Object { $Start=$True }{ if ($Start) {$Start=$False} else {$_} } | Out-File -Encoding 'ASCII' -Append -FilePath $OutFile
    }
    else {
        $ObjectCSV | Out-File -Encoding 'ASCII' -Append -FilePath $OutFile
    }

    $Mutex.ReleaseMutex()
}