function Get-GPPInnerFields {
    [CmdletBinding()]
    Param (
        $File
    )
    if ($Script:ThisModuleLoaded) {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    try {
        $Filename = Split-Path $File -Leaf
        [xml] $Xml = Get-Content ($File)

        #declare empty arrays
        $Cpassword = @()
        $UserName = @()
        $NewName = @()
        $Changed = @()
        $Password = @()

        #check for password field
        if ($Xml.innerxml -like "*cpassword*"){

            Write-Verbose "$($FunctionName): Potential password in $File"

            switch ($Filename) {

                'Groups.xml' {
                    $Cpassword += , $Xml | Select-Xml "/Groups/User/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $UserName += , $Xml | Select-Xml "/Groups/User/Properties/@userName" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $NewName += , $Xml | Select-Xml "/Groups/User/Properties/@newName" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $Changed += , $Xml | Select-Xml "/Groups/User/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                }

                'Services.xml' {
                    $Cpassword += , $Xml | Select-Xml "/NTServices/NTService/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $UserName += , $Xml | Select-Xml "/NTServices/NTService/Properties/@accountName" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $Changed += , $Xml | Select-Xml "/NTServices/NTService/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                }

                'Scheduledtasks.xml' {
                    $Cpassword += , $Xml | Select-Xml "/ScheduledTasks/Task/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $UserName += , $Xml | Select-Xml "/ScheduledTasks/Task/Properties/@runAs" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $Changed += , $Xml | Select-Xml "/ScheduledTasks/Task/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                }

                'DataSources.xml' {
                    $Cpassword += , $Xml | Select-Xml "/DataSources/DataSource/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $UserName += , $Xml | Select-Xml "/DataSources/DataSource/Properties/@username" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $Changed += , $Xml | Select-Xml "/DataSources/DataSource/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                }

                'Printers.xml' {
                    $Cpassword += , $Xml | Select-Xml "/Printers/SharedPrinter/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $UserName += , $Xml | Select-Xml "/Printers/SharedPrinter/Properties/@username" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $Changed += , $Xml | Select-Xml "/Printers/SharedPrinter/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                }

                'Drives.xml' {
                    $Cpassword += , $Xml | Select-Xml "/Drives/Drive/Properties/@cpassword" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $UserName += , $Xml | Select-Xml "/Drives/Drive/Properties/@username" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                    $Changed += , $Xml | Select-Xml "/Drives/Drive/@changed" | Select-Object -Expand Node | ForEach-Object {$_.Value}
                }
            }
        }

        foreach ($Pass in $Cpassword) {
            Write-Verbose "Decrypting $Pass"
            $DecryptedPassword = Get-DecryptedCpassword $Pass
            Write-Verbose "Decrypted a password of $DecryptedPassword"
            #append any new passwords to array
            $Password += , $DecryptedPassword
        }

        #put [BLANK] in variables
        if (!($Password)) {$Password = '[BLANK]'}
        if (!($UserName)) {$UserName = '[BLANK]'}
        if (!($Changed)) {$Changed = '[BLANK]'}
        if (!($NewName)) {$NewName = '[BLANK]'}

        #Create custom object to output results
        $ObjectProperties = @{'Passwords' = $Password;
                                'UserNames' = $UserName;
                                'Changed' = $Changed;
                                'NewName' = $NewName;
                                'File' = $File}

        $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
        Write-Verbose "The password is between {} and may be more than one value."
        if ($ResultsObject) {Return $ResultsObject}
    }

    catch {
        Write-Error $Error[0]
    }
}