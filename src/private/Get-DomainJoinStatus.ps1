function Get-DomainJoinStatus {
    $NetJoinStatus = @('Unknown', 'Unjoined', 'Workgroup', 'Domain')

    $sig = @"
[DllImport("Netapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
public static extern int NetGetJoinInformation(string server,out IntPtr domain,out int status);
"@
    $type = Add-Type -MemberDefinition $sig -Name Win32Utils -Namespace NetGetJoinInformation -PassThru
    $ptr = [IntPtr]::Zero
    $joinstatus = 0
    $null = $type::NetGetJoinInformation($null, [ref] $ptr, [ref]$joinstatus)

    $NetJoinStatus[$joinstatus]
}
