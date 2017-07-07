function Get-PathAcl {
<#
.SYNOPSIS
Enumerates the ACL for a given file path.

.DESCRIPTION
Enumerates the ACL for a given file path.

.PARAMETER Path
The local/remote path to enumerate the ACLs for.

.PARAMETER Recurse
If any ACL results are groups, recurse and retrieve user membership.

.EXAMPLE
PS C:\> Get-PathAcl "\\SERVER\Share\" 

Returns ACLs for the given UNC share.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $Path,

        [Switch]
        $Recurse
    )

    begin {

        function Convert-FileRight {

            # From http://stackoverflow.com/questions/28029872/retrieving-security-descriptor-and-getting-number-for-filesystemrights

            [CmdletBinding()]
            param(
                [Int]
                $FSR
            )

            $AccessMask = @{
              [uint32]'0x80000000' = 'GenericRead'
              [uint32]'0x40000000' = 'GenericWrite'
              [uint32]'0x20000000' = 'GenericExecute'
              [uint32]'0x10000000' = 'GenericAll'
              [uint32]'0x02000000' = 'MaximumAllowed'
              [uint32]'0x01000000' = 'AccessSystemSecurity'
              [uint32]'0x00100000' = 'Synchronize'
              [uint32]'0x00080000' = 'WriteOwner'
              [uint32]'0x00040000' = 'WriteDAC'
              [uint32]'0x00020000' = 'ReadControl'
              [uint32]'0x00010000' = 'Delete'
              [uint32]'0x00000100' = 'WriteAttributes'
              [uint32]'0x00000080' = 'ReadAttributes'
              [uint32]'0x00000040' = 'DeleteChild'
              [uint32]'0x00000020' = 'Execute/Traverse'
              [uint32]'0x00000010' = 'WriteExtendedAttributes'
              [uint32]'0x00000008' = 'ReadExtendedAttributes'
              [uint32]'0x00000004' = 'AppendData/AddSubdirectory'
              [uint32]'0x00000002' = 'WriteData/AddFile'
              [uint32]'0x00000001' = 'ReadData/ListDirectory'
            }

            $SimplePermissions = @{
              [uint32]'0x1f01ff' = 'FullControl'
              [uint32]'0x0301bf' = 'Modify'
              [uint32]'0x0200a9' = 'ReadAndExecute'
              [uint32]'0x02019f' = 'ReadAndWrite'
              [uint32]'0x020089' = 'Read'
              [uint32]'0x000116' = 'Write'
            }

            $Permissions = @()

            # get simple permission
            $Permissions += $SimplePermissions.Keys |  % {
                              if (($FSR -band $_) -eq $_) {
                                $SimplePermissions[$_]
                                $FSR = $FSR -band (-not $_)
                              }
                            }

            # get remaining extended permissions
            $Permissions += $AccessMask.Keys |
                            ? { $FSR -band $_ } |
                            % { $AccessMask[$_] }

            ($Permissions | ?{$_}) -join ","
        }
    }

    process {

        try {
            $ACL = Get-Acl -Path $Path

            $ACL.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier]) | ForEach-Object {

                $Names = @()
                if ($_.IdentityReference -match '^S-1-5-21-[0-9]+-[0-9]+-[0-9]+-[0-9]+') {
                    $Object = Get-ADObject -SID $_.IdentityReference
                    $Names = @()
                    $SIDs = @($Object.objectsid)

                    if ($Recurse -and (@('268435456','268435457','536870912','536870913') -contains $Object.samAccountType)) {
                        $SIDs += Get-NetGroupMember -SID $Object.objectsid | Select-Object -ExpandProperty MemberSid
                    }

                    $SIDs | ForEach-Object {
                        $Names += ,@($_, (Convert-SidToName $_))
                    }
                }
                else {
                    $Names += ,@($_.IdentityReference.Value, (Convert-SidToName $_.IdentityReference.Value))
                }

                ForEach($Name in $Names) {
                    $Out = New-Object PSObject
                    $Out | Add-Member Noteproperty 'Path' $Path
                    $Out | Add-Member Noteproperty 'FileSystemRights' (Convert-FileRight -FSR $_.FileSystemRights.value__)
                    $Out | Add-Member Noteproperty 'IdentityReference' $Name[1]
                    $Out | Add-Member Noteproperty 'IdentitySID' $Name[0]
                    $Out | Add-Member Noteproperty 'AccessControlType' $_.AccessControlType
                    $Out
                }
            }
        }
        catch {
            Write-Warning $_
        }
    }
}