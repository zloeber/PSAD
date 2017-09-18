Function Add-DSTranslatedUAC {
    <#
    .SYNOPSIS
    Enumerate and add additional properties for a user object for useraccountcontrol.
    .DESCRIPTION
    Enumerate and add additional properties for a user object for useraccountcontrol.
    .PARAMETER Account
    Account to process as an object with the useraccountcontrol property
    .EXAMPLE
    Get-DSUser -Enabled -IncludeAllProperties | Add-DSTranslatedUAC
    .NOTES
    author: Zachary Loeber
    http://support.microsoft.com/kb/305144
    http://msdn.microsoft.com/en-us/library/cc245514.aspx
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [cmdletbinding()]
    param (
        [Parameter(HelpMessage='User or users to process.', Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Account','User','Computer')]
        [psobject]$Identity
    )

    Begin {
        $Identities = @()
    }
    Process {
        $Identities += $Identity
    }
    End {
        Foreach ($Identity in $Identities) {
            if ($Identity.PSObject.Properties.Match('useraccountcontrol').Count) {
                try {
                    $UAC = [Enum]::Parse('userAccountControlFlags', $Identity.useraccountcontrol)
                    $Script:UACAttribs | ForEach-Object {
                        Add-Member -InputObject $Identity -MemberType NoteProperty -Name $_ -Value ($UAC -match $_) -Force
                    }
                }
                catch {
                    Write-Warning -Message ('Append-ADUserAccountControl: {0}' -f $_.Exception.Message)
                }
            }
            $Identity
        }
    }
}