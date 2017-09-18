## Pre-Loaded Module code ##

<#
 Put all code that must be run prior to function dot sourcing here.

 This is a good place for module variables as well. The only rule is that no
 variable should rely upon any of the functions in your module as they
 will not have been loaded yet. Also, this file cannot be completely
 empty. Even leaving this comment is good enough.
#>

# Several variables exposed and used with AD connections
[string]$CurrentServer = $null
[string]$CurrentBaseDN = $null
[string]$LastLDAPFilter = ''
$LastSearchSetting = New-Object -TypeName PSObject -Property @{
    ComputerName = ''
    SearchRoot = ''
    SearchScope = ''
    Credential = ''
    Filter = ''
    Properties = ''
    SecurityMask = ''
    Tombstone = $false
    Limit = 0
}

$SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Credential = $Credential
            Filter = $FinalLDAPFilter
            Properties = $Properties
            SecurityMask = $SecurityMask
        }
[Management.Automation.PSCredential]$CurrentCredential = $null
[System.DirectoryServices.ActiveDirectory.Domain]$CurrentDomain = $null
[System.DirectoryServices.ActiveDirectory.Forest]$CurrentForest = $null
[System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]$CurrentSchema = $null

# The pagesize that will be used across any functions where pagesize is used
[int]$PageSize = 1000

##################
## Module Globals ##
##################

# A dictionary with basic information about attributes (read from schema). We populate this as needed.
$__ad_schema_info=@{}

$IsPS5 = ($PSVersionTable.PSVersion).Major -ge 5

<#
if ($IsPS5) {
    Write-Verbose "Powershell version 5 detected, using builtin Flags instead of add-type definitions."
    [Flags()] enum userAccountControlFlags {
        SCRIPT = 0x0001
        ACCOUNTDISABLE = 0x0002
        HOMEDIR_REQUIRED = 0x0008
        LOCKOUT = 0x0010
        PASSWD_NOTREQD = 0x0020
        PASSWD_CANT_CHANGE = 0x0040
        ENCRYPTED_TEXT_PWD_ALLOWED = 0x0080
        TEMP_DUPLICATE_ACCOUNT = 0x0100
        NORMAL_ACCOUNT = 0x0200
        INTERDOMAIN_TRUST_ACCOUNT = 0x0800
        WORKSTATION_TRUST_ACCOUNT = 0x1000
        SERVER_TRUST_ACCOUNT = 0x2000
        DONT_EXPIRE_PASSWORD = 0x10000
        MNS_LOGON_ACCOUNT = 0x20000
        SMARTCARD_REQUIRED = 0x40000
        TRUSTED_FOR_DELEGATION = 0x80000
        NOT_DELEGATED = 0x100000
        USE_DES_KEY_ONLY = 0x200000
        DONT_REQ_PREAUTH = 0x400000
        PASSWORD_EXPIRED = 0x800000
        TRUSTED_TO_AUTH_FOR_DELEGATION = 0x1000000
        PARTIAL_SECRETS_ACCOUNT = 0x04000000
    }

    [Flags()] enum nTDSSiteConnectionSettingsFlags {
        IS_GENERATED = 1
        TWOWAY_SYNC = 2
        OVERRIDE_NOTIFY_DEFAULT = 4
        USE_NOTIFY = 8
        DISABLE_INTERSITE_COMPRESSION = 10
        OPT_USER_OWNED_SCHEDULE = 20
    }
    [Flags()] enum MSExchCurrentServerRolesFlags {
        NONE = 1
        MAILBOX = 2
        CLIENT_ACCESS = 4
        UM = 10
        HUB_TRANSPORT  = 20
        EDGE_TRANSPORT = 40
    }
    [Flags()] enum nTDSSiteSettingsFlags {
        IS_AUTO_TOPOLOGY_DISABLED = 1
        IS_TOPL_CLEANUP_DISABLED = 2
        IS_TOPL_MIN_HOPS_DISABLED = 4
        IS_TOPL_DETECT_STALE_DISABLED = 8
        IS_INTER_SITE_AUTO_TOPOLOGY_DISABLED = 10
        IS_GROUP_CACHING_ENABLED = 20
        FORCE_KCC_WHISTLER_BEHAVIOR = 40
        FORCE_KCC_W2K_ELECTION = 80
        IS_RAND_BH_SELECTION_DISABLED = 100
        IS_SCHEDULE_HASHING_ENABLED = 200
        IS_REDUNDANT_SERVER_TOPOLOGY_ENABLED = 400
    }
    [Flags()] enum MSTrustAttributeFlags {
        NON_TRANSITIVE = 1
        UPLEVEL_ONLY = 2
        QUARANTINED_DOMAIN = 4
        FOREST_TRANSITIVE = 8
        CROSS_ORGANIZATION = 10
        WITHIN_FOREST = 20
        TREAT_AS_EXTERNAL  = 40
        USES_RC4_ENCRYPTION = 80
    }
}#>

Add-Type -TypeDefinition @"
    [System.Flags]
    public enum userAccountControlFlags {
        SCRIPT = 0x0001,
        ACCOUNTDISABLE = 0x0002,
        HOMEDIR_REQUIRED = 0x0008,
        LOCKOUT = 0x0010,
        PASSWD_NOTREQD = 0x0020,
        PASSWD_CANT_CHANGE = 0x0040,
        ENCRYPTED_TEXT_PWD_ALLOWED = 0x0080,
        TEMP_DUPLICATE_ACCOUNT = 0x0100,
        NORMAL_ACCOUNT = 0x0200,
        INTERDOMAIN_TRUST_ACCOUNT = 0x0800,
        WORKSTATION_TRUST_ACCOUNT = 0x1000,
        SERVER_TRUST_ACCOUNT = 0x2000,
        DONT_EXPIRE_PASSWORD = 0x10000,
        MNS_LOGON_ACCOUNT = 0x20000,
        SMARTCARD_REQUIRED = 0x40000,
        TRUSTED_FOR_DELEGATION = 0x80000,
        NOT_DELEGATED = 0x100000,
        USE_DES_KEY_ONLY = 0x200000,
        DONT_REQ_PREAUTH = 0x400000,
        PASSWORD_EXPIRED = 0x800000,
        TRUSTED_TO_AUTH_FOR_DELEGATION = 0x1000000,
        PARTIAL_SECRETS_ACCOUNT = 0x04000000,
    }
"@

Add-Type -TypeDefinition @"
    [System.Flags]
    public enum nTDSSiteConnectionSettingsFlags {
        IS_GENERATED                  = 0x00000001,
        TWOWAY_SYNC                   = 0x00000002,
        OVERRIDE_NOTIFY_DEFAULT       = 0x00000004,
        USE_NOTIFY                    = 0x00000008,
        DISABLE_INTERSITE_COMPRESSION = 0x00000010,
        OPT_USER_OWNED_SCHEDULE       = 0x00000020
    }
    [System.Flags]
    public enum MSExchCurrentServerRolesFlags {
        NONE           = 0x00000001,
        MAILBOX        = 0x00000002,
        CLIENT_ACCESS  = 0x00000004,
        UM             = 0x00000010,
        HUB_TRANSPORT  = 0x00000020,
        EDGE_TRANSPORT = 0x00000040
    }
    [System.Flags]
    public enum nTDSSiteSettingsFlags {
        IS_AUTO_TOPOLOGY_DISABLED            = 0x00000001,
        IS_TOPL_CLEANUP_DISABLED             = 0x00000002,
        IS_TOPL_MIN_HOPS_DISABLED            = 0x00000004,
        IS_TOPL_DETECT_STALE_DISABLED        = 0x00000008,
        IS_INTER_SITE_AUTO_TOPOLOGY_DISABLED = 0x00000010,
        IS_GROUP_CACHING_ENABLED             = 0x00000020,
        FORCE_KCC_WHISTLER_BEHAVIOR          = 0x00000040,
        FORCE_KCC_W2K_ELECTION               = 0x00000080,
        IS_RAND_BH_SELECTION_DISABLED        = 0x00000100,
        IS_SCHEDULE_HASHING_ENABLED          = 0x00000200,
        IS_REDUNDANT_SERVER_TOPOLOGY_ENABLED = 0x00000400
    }
    [System.Flags]
    public enum MSTrustAttributeFlags {
        NON_TRANSITIVE      = 0x00000001,
        UPLEVEL_ONLY        = 0x00000002,
        QUARANTINED_DOMAIN  = 0x00000004,
        FOREST_TRANSITIVE   = 0x00000008,
        CROSS_ORGANIZATION  = 0x00000010,
        WITHIN_FOREST       = 0x00000020,
        TREAT_AS_EXTERNAL   = 0x00000040,
        USES_RC4_ENCRYPTION = 0x00000080
    }
"@

$UACAttribs = @(
    'SCRIPT',
    'ACCOUNTDISABLE',
    'HOMEDIR_REQUIRED',
    'LOCKOUT',
    'PASSWD_NOTREQD',
    'PASSWD_CANT_CHANGE',
    'ENCRYPTED_TEXT_PWD_ALLOWED',
    'TEMP_DUPLICATE_ACCOUNT',
    'NORMAL_ACCOUNT',
    'INTERDOMAIN_TRUST_ACCOUNT',
    'WORKSTATION_TRUST_ACCOUNT',
    'SERVER_TRUST_ACCOUNT',
    'DONT_EXPIRE_PASSWORD',
    'MNS_LOGON_ACCOUNT',
    'SMARTCARD_REQUIRED',
    'TRUSTED_FOR_DELEGATION',
    'NOT_DELEGATED',
    'USE_DES_KEY_ONLY',
    'DONT_REQ_PREAUTH',
    'PASSWORD_EXPIRED',
    'TRUSTED_TO_AUTH_FOR_DELEGATION',
    'PARTIAL_SECRETS_ACCOUNT'
)

# Hash of different GUIDs for gpo settings
$GPOGuidRef = @{
    '{00000000-0000-0000-0000-000000000000}' = 'Core GPO Engine'
    '{0ACDD40C-75AC-47AB-BAA0-BF6DE7E7FE63}' = 'Wireless Group Policy'
    '{0E28E245-9368-4853-AD84-6DA3BA35BB75}' = 'Group Policy Environment'
    '{0F3F3735-573D-9804-99E4-AB2A69BA5FD4}' = 'Computer Policy Setting'
    '{0F6B957D-509E-11D1-A7CC-0000F87571E3}' = 'Tool Extension GUID (Computer Policy Settings)'
    '{0F6B957E-509E-11D1-A7CC-0000F87571E3}' = 'Tool Extension GUID (User Policy Settings) Restrict Run'
    '{1612B55C-243C-48DD-A449-FFC097B19776}' = 'Data Sources'
    '{16BE69FA-4209-4250-88CB-716CF41954E0}' = 'Central Access Policy Configuration'
    '{17D89FEC-5C44-4972-B12D-241CAEF74509}' = 'Group Policy Local Users and Groups'
    '{1A6364EB-776B-4120-ADE1-B63A406A76B5}' = 'Group Policy Device Settings'
    '{1B767E9A-7BE4-4D35-85C1-2E174A7BA951}' = 'Devices'
    '{25537BA6-77A8-11D2-9B6C-0000F8080861}' = 'Folder Redirection'
    '{2A8FDC61-2347-4C87-92F6-B05EB91A201A}' = 'MitigationOptions'
    '{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}' = 'Drives'
    '{3060E8CE-7020-11D2-842D-00C04FA372D4}' = 'Remote Installation Services'
    '{346193F5-F2FD-4DBD-860C-B88843475FD3}' = 'ConfigMgr User State Management Extension'
    '{35141B6B-498A-4CC7-AD59-CEF93D89B2CE}' = 'Environment Variables'
    '{35378EAC-683F-11D2-A89A-00C04FBBCFA2}' = 'Registry Settings'
    '{3610EDA5-77EF-11D2-8DC5-00C04FA31A66}' = 'Microsoft Disk Quota'
    '{3A0DBA37-F8B2-4356-83DE-3E90BD5C261F}' = 'Group Policy Network Options'
    '{3BAE7E51-E3F4-41D0-853D-9BB9FD47605F}' = 'Files'
    '{3BFAE46A-7F3A-467B-8CEA-6AA34DC71F53}' = 'Folder Options'
    '{3EC4E9D3-714D-471F-88DC-4DD4471AAB47}' = 'Folders'
    '{40B6664F-4972-11D1-A7CA-0000F87571E3}' = 'Scripts (Startup/Shutdown)'
    '{40B66650-4972-11D1-A7CA-0000F87571E3}' = 'Scripts (Logon/Logoff) Run Restriction'
    '{426031C0-0B47-4852-B0CA-AC3D37BFCB39}' = 'QoS Packet Scheduler'
    '{42B5FAAE-6536-11D2-AE5A-0000F87571E3}' = 'Scripts'
    '{47BA4403-1AA0-47F6-BDC5-298F96D1C2E3}' = 'Print Policy in PolicyMaker'
    '{4BCD6CDE-777B-48B6-9804-43568E23545D}' = 'Remote Desktop USB Redirection'
    '{4CFB60C1-FAA6-47F1-89AA-0B18730C9FD3}' = 'Internet Explorer Zonemapping'
    '{4D2F9B6F-1E52-4711-A382-6A8B1A003DE6}' = 'RADCProcessGroupPolicyEx'
    '{4D968B55-CAC2-4FF5-983F-0A54603781A3}' = 'Work Folders'
    '{516FC620-5D34-4B08-8165-6A06B623EDEB}' = 'Ini Files'
    '{53D6AB1B-2488-11D1-A28C-00C04FB94F17}' = 'EFS Policy'
    '{53D6AB1D-2488-11D1-A28C-00C04FB94F17}' = 'Certificates Run Restriction'
    '{5794DAFD-BE60-433F-88A2-1A31939AC01F}' = 'Group Policy Drive Maps'
    '{5C935941-A954-4F7C-B507-885941ECE5C4}' = 'Internet Settings'
    '{6232C319-91AC-4931-9385-E70C2B099F0E}' = 'Group Policy Folders'
    '{6A4C88C6-C502-4F74-8F60-2CB23EDC24E2}' = 'Group Policy Network Shares'
    '{7150F9BF-48AD-4DA4-A49C-29EF4A8369BA}' = 'Group Policy Files'
    '{728EE579-943C-4519-9EF7-AB56765798ED}' = 'Group Policy Data Sources'
    '{74EE6C03-5363-4554-B161-627540339CAB}' = 'Group Policy Ini Files'
    '{7933F41E-56F8-41D6-A31C-4148A711EE93}' = 'Windows Search Group Policy Extension'
    '{79F92669-4224-476C-9C5C-6EFB4D87DF4A}' = 'Local users and groups'
    '{7B849A69-220F-451E-B3FE-2CB811AF94AE}' = 'Internet Explorer User Accelerators'
    '{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}' = 'Computer Restricted Groups'
    '{827D319E-6EAC-11D2-A4EA-00C04F79F83A}' = 'Security'
    '{88E729D6-BDC1-11D1-BD2A-00C04FB9603F}' = 'Folder Redirection'
    '{8A28E2C5-8D06-49A4-A08C-632DAA493E17}' = 'Deployed Printer Configuration'
    '{91FBB303-0CD5-4055-BF42-E512A681B325}' = 'Group Policy Services'
    '{942A8E4F-A261-11D1-A760-00C04FB9603F}' = 'Software Installation (Computers)'
    '{949FB894-E883-42C6-88C1-29169720E8CA}' = 'Network Options'
    '{9AD2BAFE-63B4-4883-A08C-C3C6196BCAFD}' = 'Power Options'
    '{A2E30F80-D7DE-11D2-BBDE-00C04F86AE3B}' = 'Internet Explorer Branding'
    '{A3F3E39B-5D83-4940-B954-28315B82F0A8}' = 'Group Policy Folder Options'
    '{A8C42CEA-CDB8-4388-97F4-5831F933DA84}' = 'Printers'
    '{AADCED64-746C-4633-A97C-D61349046527}' = 'Group Policy Scheduled Tasks'
    '{B05566AC-FE9C-4368-BE01-7A4CBB6CBA11}' = 'Windows Firewall'
    '{B087BE9D-ED37-454F-AF9C-04291E351182}' = 'Group Policy Registry'
    '{B1BE8D72-6EAC-11D2-A4EA-00C04F79F83A}' = 'EFS Recovery'
    '{B587E2B1-4D59-4E7E-AED9-22B9DF11D053}' = '802.3 Group Policy'
    '{B9CCA4DE-E2B9-4CBD-BF7D-11B6EBFBDDF7}' = 'Regional Options'
    '{BA649533-0AAC-4E04-B9BC-4DBAE0325B12}' = 'Windows To Go Startup Options'
    '{BACF5C8A-A3C7-11D1-A760-00C04FB9603F}' = 'Software Installation (Users) Run Restriction'
    '{BC75B1ED-5833-4858-9BB8-CBF0B166DF9D}' = 'Group Policy Printers'
    '{BEE07A6A-EC9F-4659-B8C9-0B1937907C83}' = 'Registry'
    '{BFCBBEB0-9DF4-4C0C-A728-434EA66A0373}' = 'Network Shares'
    '{C34B2751-1CF4-44F5-9262-C3FC39666591}' = 'Windows To Go Hibernate Options'
    '{C418DD9D-0D14-4EFB-8FBF-CFE535C8FAC7}' = 'Group Policy Shortcuts'
    '{C631DF4C-088F-4156-B058-4375F0853CD8}' = 'Microsoft Offline Files'
    '{C6DC5466-785A-11D2-84D0-00C04FB169F7}' = 'Software Installation'
    '{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}' = 'Scheduled Tasks'
    '{CC5746A9-9B74-4BE5-AE2E-64379C86E0E4}' = 'Services'
    '{CDEAFC3D-948D-49DD-AB12-E578BA4AF7AA}' = 'TCPIP'
    '{CEFFA6E2-E3BD-421B-852C-6F6A79A59BC1}' = 'Shortcuts'
    '{CF7639F3-ABA2-41DB-97F2-81E2C5DBFC5D}' = 'Internet Explorer Machine Accelerators'
    '{CF848D48-888D-4F45-B530-6A201E62A605}' = 'Start Menu'
    '{D02B1F72-3407-48AE-BA88-E8213C6761F1}' = 'Tool Extension GUID (Computer Policy Settings)'
    '{D02B1F73-3407-48AE-BA88-E8213C6761F1}' = 'Tool Extension GUID (User Policy Settings)'
    '{D76B9641-3288-4F75-942D-087DE603E3EA}' = 'AdmPwd (LAPS)'
    '{E437BC1C-AA7D-11D2-A382-00C04F991E27}' = 'IP Security'
    '{E47248BA-94CC-49C4-BBB5-9EB7F05183D0}' = 'Group Policy Internet Settings'
    '{E4F48E54-F38D-4884-BFB9-D4D2E5729C18}' = 'Group Policy Start Menu Settings'
    '{E5094040-C46C-4115-B030-04FB2E545B00}' = 'Group Policy Regional Options'
    '{E62688F0-25FD-4C90-BFF5-F508B9D2E31F}' = 'Group Policy Power Options'
    '{F0DB2806-FD46-45B7-81BD-AA3744B32765}' = 'Policy Maker'
    '{F17E8B5B-78F2-49A6-8933-7B767EDA5B41}' = 'Policy Maker'
    '{F27A6DA8-D22B-4179-A042-3D715F9E75B5}' = 'Policy Maker'
    '{F312195E-3D9D-447A-A3F5-08DFFA24735E}' = 'ProcessVirtualizationBasedSecurityGroupPolicy'
    '{F3CCC681-B74C-4060-9F26-CD84525DCA2A}' = 'Audit Policy Configuration'
    '{F581DAE7-8064-444A-AEB3-1875662A61CE}' = 'Policy Maker'
    '{F648C781-42C9-4ED4-BB24-AEB8853701D0}' = 'Policy Maker'
    '{F6E72D5A-6ED3-43D9-9710-4440455F6934}' = 'Policy Maker'
    '{F9C77450-3A41-477E-9310-9ACD617BD9E3}' = 'Group Policy Applications'
    '{FB2CA36D-0B40-4307-821B-A13B252DE56C}' = 'Policy-based QoS'
    '{FBF687E6-F063-4D9F-9F4F-FD9A26ACDD5F}' = 'Connectivity Platform'
    '{FC491EF1-C4AA-4CE1-B329-414B101DB823}' = 'ProcessConfigCIPolicyGroupPolicy'
    '{FC715823-C5FB-11D1-9EEF-00A0C90347FF}' = 'Internet Explorer Maintenance Extension protocol'
    '{FD2D917B-6519-4BF7-8403-456C0C64312F}' = 'Policy Maker'
    '{FFC64763-70D2-45BC-8DEE-7ACAF1BA7F89}' = 'Policy Maker'
}

$SchemaVersionTable = @{
    '13' = 'Windows 2000'
    '30' = 'Windows 2003'
    '31' = 'Windows 2003 R2'
    '39' = 'Windows 2008 BETA'
    '44' = 'Windows 2008'
    '47' = 'Windows 2008 R2'
    '51' = 'Windows Server 8 Developer Preview'
    '52' = 'Windows Server 8 BETA'
    '56' = 'Windows Server 2012'
    '69' = 'Windows Server 2012 R2'
    '81' = 'Windows Server 2016 Technical Preview'
    '4397' = 'Exchange 2000 RTM'
    '4406' = 'Exchange 2000 SP3'
    '6870' = 'Exchange 2003 RTM'
    '6936' = 'Exchange 2003 SP3'
    '10637' = 'Exchange 2007 RTM'
    '11116' = 'Exchange 2007 RTM'
    '14622' = 'Exchange 2007 SP2 & Exchange 2010 RTM'
    '14625' = 'Exchange 2007 SP3'
    '14726' = 'Exchange 2010 SP1'
    '14732' = 'Exchange 2010 SP2'
    '14734' = 'Exchange 2010 SP3'
    '15137' = 'Exchange 2013 RTM'
    '15254' = 'Exchange 2013 CU1'
    '15281' = 'Exchange 2013 CU2'
    '15283' = 'Exchange 2013 CU3'
    '15292' = 'Exchange 2013 SP1/CU4'
    '15300' = 'Exchange 2013 CU5'
    '15303' = 'Exchange 2013 CU6'
    '15312' = 'Exchange 2013 CU7/CU8/CU9'
    '15317' = 'Exchange 2016 Preview'
    '1006' = 'Live Communications Server 2005'
    '1007' = 'Office Communications Server 2007 R1'
    '1008' = 'Office Communications Server 2007 R2'
    '1100' = 'Lync Server 2010'
    '1150' = 'Lync Server 2013'
    '4.00.5135.0000'='SCCM 2007 Beta 1'
    '4.00.5931.0000'='SCCM 2007 RTM'
    '4.00.6221.1000'='SCCM 2007 SP1/R2'
    '4.00.6221.1193'='SCCM 2007 SP1 (KB977203)'
    '4.00.6487.2000'='SCCM 2007 SP2'
    '4.00.6487.2111'='SCCM 2007 SP2 (KB977203)'
    '4.00.6487.2157'='SCCM 2007 R3'
    '4.00.6487.2207'='SCCM 2007 SP2 (KB2750782)'
    '5.00.7561.0000'='SCCM 2012 Beta 2'
    '5.00.7678.0000'='SCCM 2012 RC1'
    '5.00.7703.0000'='SCCM 2012 RC2'
    '5.00.7711.0000'='SCCM 2012 RTM'
    '5.00.7711.0200'='SCCM 2012 CU1'
    '5.00.7711.0301'='SCCM 2012 CU2'
    '5.00.7782.1000'='SCCM 2012 SP1 Beta'
    '5.00.7804.1000'='SCCM 2012 SP1'
    '5.00.7804.1202'='SCCM 2012 SP1 CU1'
    '5.00.7804.1300'='SCCM 2012 SP1 CU2'
    '5.00.7804.1400'='SCCM 2012 SP1 CU3'
    '5.00.7804.1500'='SCCM 2012 SP1 CU4'
    '5.00.7958.1000'='SCCM 2012 R2'
}

$ExchangeServerVersions = @{
    '6.5' = '2003 RTM/SP1/SP2'
    '8.0' = '2007'
    '8.1' = '2007 SP1'
    '8.2' = '2007 SP2'
    '8.3' = '2007 SP3'
    '14.0' = '2010 RTM'
    '14.1' = '2010 SP1'
    '14.2' = '2010 SP2'
    '14.3' = '2010 SP3'
    '15.0' = '2013'
    '15.1' = '2016'
}

# AD DC capabilities list (http://www.ldapexplorer.com/en/manual/103010700-connection-rootdse.htm)
# - Primarily used to determine if a DC is RODC or not (Const LDAP_CAP_ACTIVE_DIRECTORY_PARTIAL_SECRETS_OID = "1.2.840.113556.1.4.1920")
$AD_Capabilities = @{
    '1.2.840.113556.1.4.319' = 'Paged results'
    '1.2.840.113556.1.4.417' = 'Show deleted objects'
    '1.2.840.113556.1.4.473' = 'Sort results'
    '1.2.840.113556.1.4.474' = 'Sort results response'
    '1.2.840.113556.1.4.521' = 'Cross domain move'
    '1.2.840.113556.1.4.528' = 'Server notification'
    '1.2.840.113556.1.4.529' = 'Extended DN'
    '1.2.840.113556.1.4.619' = 'Lazy commit'
    '1.2.840.113556.1.4.800' = 'Active Directory >= Windows 2000'
    '1.2.840.113556.1.4.801' = 'SD flags'
    '1.2.840.113556.1.4.805' = 'Tree delete'
    '1.2.840.113556.1.4.906' = 'Microsoft large integer'
    '1.2.840.113556.1.4.1302' = 'Microsoft OID used with DEN Attributes'
    '1.2.840.113556.1.4.1338' = 'Verify name'
    '1.2.840.113556.1.4.1339' = 'Domain scope'
    '1.2.840.113556.1.4.1340' = 'Search options'
    '1.2.840.113556.1.4.1341' = 'RODC DCPROMO'
    '1.2.840.113556.1.4.1413' = 'Permissive Modify'
    '1.2.840.113556.1.4.1670' = 'Active Directory (v5.1)>= Windows 2003'
    '1.2.840.113556.1.4.1781' = 'Microsoft LDAP fast bind extended request'
    '1.2.840.113556.1.4.1791' = 'NTLM Signing and Sealing'
    '1.2.840.113556.1.4.1851' = 'ADAM / AD LDS Supported'
    '1.2.840.113556.1.4.1852' = 'Quota Control'
    '1.2.840.113556.1.4.1880' = 'ADAM Digest'
   # '1.2.840.113556.1.4.1852' = 'Shutdown Notify'
    '1.2.840.113556.1.4.1920' = 'Partial Secrets'
    '1.2.840.113556.1.4.1935' = 'Active Directory (v6.0) >= Windows 2008'
    '1.2.840.113556.1.4.1947' = 'Force Update'
    '1.2.840.113556.1.4.1948' = 'Range Retrieval No Error'
    '1.2.840.113556.1.4.2026' = 'Input DN'
    '1.2.840.113556.1.4.2064' = 'Show Recycled'
    '1.2.840.113556.1.4.2065' = 'Show Deactivated Link'
    '1.2.840.113556.1.4.2080' = 'Active Directory (v6.1) >= Windows 2008 R2'
}

$Attrib_User_MSExchangeVersion = @{
    # $null = Exchange 2003 and earlier
    '4535486012416' = '2007'
    '44220983382016' = '2010'
}

$DomainFunctionalLevel = @{
    '0' = 'Windows 2000 Native'
    '1' = 'Windows Server 2003 Interim'
    '2' = 'Windows Server 2003'
    '3' = 'Windows Server 2008'
    '4' = 'Windows Server 2008 R2'
    '5' = 'Windows Server 2012'
    '6' = 'Windows Server 2012 R2'
}

$ForestFunctionalLevel = @{
    '0' = 'Windows 2000 Native'
    '1' = 'Windows Server 2003 Interim'
    '2' = 'Windows Server 2003'
    '3' = 'Windows Server 2008'
    '4' = 'Windows Server 2008 R2'
    '5' = 'Windows Server 2012'
    '6' = 'Windows Server 2012 R2'
}

$GuidMap = @{}

## PRIVATE MODULE FUNCTIONS AND DATA ##

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


function ConvertTo-SecurityIdentifier
{
    <#
    .SYNOPSIS
    Converts a string or byte array security identifier into a `System.Security.Principal.SecurityIdentifier` object.

    .PARAMETER SID
    The SID to convert to a `System.Security.Principal.SecurityIdentifier`. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.

    .DESCRIPTION
    Converts a SID in SDDL form (as a string), in binary form (as a byte array) into a System.Security.Principal.SecurityIdentifier object. It also accepts System.Security.Principal.SecurityIdentifier objects, and returns them back to you.

    If the string or byte array don't represent a SID, an error is written and nothing is returned.

    .EXAMPLE
    ConvertTo-SecurityIdentifier -SID 'S-1-5-21-2678556459-1010642102-471947008-1017'

    Demonstrates how to convert a a SID in SDDL into a `System.Security.Principal.SecurityIdentifier` object.

    .EXAMPLE
    ConvertTo-SecurityIdentifier -SID (New-Object 'Security.Principal.SecurityIdentifier' 'S-1-5-21-2678556459-1010642102-471947008-1017')

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter. The SID you passed in will be returned to you unchanged.

    .EXAMPLE
    ConvertTo-SecurityIdentifier -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $SID
    )

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    try
    {
        if( $SID -is [string] )
        {
            New-Object 'Security.Principal.SecurityIdentifier' $SID
        }
        elseif( $SID -is [byte[]] )
        {
            New-Object 'Security.Principal.SecurityIdentifier' $SID,0
        }
        elseif( $SID -is [Security.Principal.SecurityIdentifier] )
        {
            $SID
        }
        else
        {
            Write-Error ('Invalid SID. The `SID` parameter accepts a `System.Security.Principal.SecurityIdentifier` object, a SID in SDDL form as a `string`, or a SID in binary form as byte array. You passed a ''{0}''.' -f $SID.GetType())
            return
        }
    }
    catch
    {
        Write-Error ('Exception converting SID parameter to a `SecurityIdentifier` object. This usually means you passed an invalid SID in SDDL form (as a string) or an invalid SID in binary form (as a byte array): {0}' -f $_.Exception.Message)
        return
    }
}


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


function Get-CallerPreference {
    <#
    .Synopsis
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]$SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]$Name
    )

    begin {
        $filterHash = @{}
    }
    
    process {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }

        foreach ($entry in $vars.GetEnumerator()) {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name))) {
                
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
                
                if ($null -ne $variable) {
                    if ($SessionState -eq $ExecutionContext.SessionState) {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered') {
            foreach ($varName in $filterHash.Keys) {
                if (-not $vars.ContainsKey($varName)) {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)
                
                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }
    }
}

Function Get-CombinedLDAPFilter {
	<#
    .SYNOPSIS
    A helper function for combining LDAP filters.
    .DESCRIPTION
	A helper function for combining LDAP filters.
    .PARAMETER Filter
	LDAP filters to combine.
	.PARAMETER Conditional
	AD object to search for.

    .EXAMPLE
	NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
	#>
	[CmdletBinding()]
	param (
		[Parameter( Position = 0, ValueFromPipeline = $True )]
		[String[]]$Filter,
		[Parameter( Position = 1 )]
		[String]$Conditional = '&'
	)
	begin {
		# Function initialization
		if ($Script:ThisModuleLoaded) {
			Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		}
		$FunctionName = $MyInvocation.MyCommand.Name
		$Filters = @()
	}
	process {
		$Filters += $Filter
	}

	end {
		$Filters = $Filters | Where-Object {-not [string]::IsNullOrEmpty($_)} | Select-Object -Unique
		Write-Verbose "$($FunctionName): All passed filters = $($Filters -join ', ')"
		switch ($Filters.Count) {
			0 {
				Write-Verbose "$($FunctionName): No filters passed, returning nothing."
				$FinalFilter = $null
			}
			1 {
				Write-Verbose "$($FunctionName): One filter passed, NOT using conditional."
				$FinalFilter = "($Filters)"
			}
			Default {
				Write-Verbose "$($FunctionName): Multiple filters passed, using conditional ($Conditional)."
				$FinalFilter = "($Conditional({0}))" -f ($Filters -join ')(')
			}
		}

		Write-Verbose "$($FunctionName): Final combined filter = $FinalFilter"
		$FinalFilter
	}
}

Function Get-CommandParams {
    <#
    .SYNOPSIS
        Get available parameters for a command.
    .DESCRIPTION
        Get available parameters for a command. This skips default parameters.
    #>
    [System.Diagnostics.DebuggerStepThrough()]
    param(
        # The name of the command being proxied.
        [System.String]
        $CommandName,

        # The type of the command being proxied. Valid values include 'Cmdlet' or 'Function'.
        [System.Management.Automation.CommandTypes]
        $CommandType
    )
    try {
        # Look up the command being proxied.
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand($CommandName, $CommandType)

        #If the command was not found, throw an appropriate command not found exception.
        if (-not $wrappedCmd) {
            $PSCmdlet.ThrowCommandNotFoundError($CommandName, $PSCmdlet.MyInvocation.MyCommand.Name)
        }

        # Lookup the command metadata.
        (New-Object -TypeName System.Management.Automation.CommandMetadata -ArgumentList $wrappedCmd).Parameters.Keys
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

Function Get-CommonIDLDAPFilter {
    <#
    .SYNOPSIS
    A helper function for creating an LDAP filter for an AD object based on identity.
    .DESCRIPTION
    A helper function for creating an LDAP filter for an AD object based on identity.
    .PARAMETER Identity
    AD object to search for.
    .PARAMETER Filter
	LDAP filter for searches.
	.PARAMETER LiteralFilter
    Escapes special characters in the filter ()/\*`0

    .EXAMPLE
    NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param (
		[Parameter()]
		[String]$Identity,
        [Parameter()]
        [String[]]$Filter,
        [Parameter()]
        [bool]$LiteralFilter
    )
    # Function initialization
    if ($Script:ThisModuleLoaded) {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    if ([string]::IsNullOrEmpty($Identity)) {
        # If no identity is passed and no filter is passed then use a generic filter
        if ($Filter.Count -eq 0) {
            $Filter = @('distinguishedName=*')
        }
    }
    else {
        # Otherwise use OR logic with some fuzzy matching for the ID
        Write-Verbose "$($FunctionName): Identity passed ($ObjID), any existing filters will be ignored."
        if ($LiteralFilter) {
			Write-Verbose "$($FunctionName): Literal flag set, formatting filter..."
            $ObjID = Format-DSSearchFilterValue -SearchString $Identity
        }
        else {
            $ObjID = $Identity
        }

        # Do this to capture regular accounts as well as computer accounts (include a $ at the end)
        $SAMNameFilter = @("samaccountname=$ObjID","samaccountname=$ObjID$")
        $Filter = @("distinguishedName=$ObjID","objectGUID=$ObjID",,"cn=$ObjID") + (Get-CombinedLDAPFilter -Filter $SAMNameFilter -Conditional '|')
    }

    Get-CombinedLDAPFilter -Filter $Filter -Conditional '|'
}

function Get-CommonParameters {
    # Helper function to get all the automatically added parameters in an
    # advanced function
    function somefunct {
        [CmdletBinding(SupportsShouldProcess = $true, SupportsPaging = $true, SupportsTransactions = $true)]
        param()
    }

    ((Get-Command somefunct).Parameters).Keys
}

function Get-CommonSearcherParams {
    <#
    .SYNOPSIS
    Constuct parameters for the most common searches.
    .DESCRIPTION
    Constuct search parameters from the most common PSAD parameters. This creates a hashtable
    suitable for get-dsdirectorysearcher.
    .PARAMETER Identity
    AD object to search for.
    .PARAMETER ComputerName
    Domain controller to use for this search.
    .PARAMETER Credential
    Credentials to use for connection to AD.
    .PARAMETER Limit
    Limits items retrieved. If set to 0 then there is no limit.
    .PARAMETER PageSize
    Items returned per page.
    .PARAMETER SearchRoot
    Root of search.
    .PARAMETER Filter
    User passed LDAP filter for searches.
    .PARAMETER BaseFilter
    Other LDAP filters for specific searches (like user or computer)
    .PARAMETER Properties
    Properties to include in output.
    .PARAMETER SearchScope
    Scope of a search as either a base, one-level, or subtree search, default is subtree.
    .PARAMETER SecurityMask
    Specifies the available options for examining security information of a directory object.
    .PARAMETER TombStone
    Whether the search should also return deleted objects that match the search filter.
    .PARAMETER Raw
    Skip attempts to convert known property types.
    .PARAMETER IncludeAllProperties
    Include all properties for an object.
    .PARAMETER IncludeNullProperties
    Include unset (null) properties as defined in the schema (with or without values). This overrides the Properties parameter and can be extremely verbose.
    .PARAMETER ModifiedAfter
    Account was modified after this time
    .PARAMETER ModifiedBefore
    Account was modified before this time
    .PARAMETER CreatedAfter
    Account was created after this time
    .PARAMETER CreatedBefore
    Account was created before this time
    .PARAMETER ChangeLogicOrder
    Alter LDAP filter logic to use OR instead of AND
    .PARAMETER DontJoinAttributeValues
    Output will automatically join the attributes unless this switch is set.
    .PARAMETER ExpandUAC
    Expands the UAC attribute into readable format.
    .PARAMETER Raw
    Skip attempts to convert known property types.
    .PARAMETER LiteralFilter
    Escapes special characters in the filter ()/\*`0
    .EXAMPLE
    NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter( Position = 0 )]
        [Alias('User', 'Name', 'sAMAccountName', 'distinguishedName')]
        [string]$Identity,

        [Parameter( Position = 1 )]
        [Alias('Server', 'ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position = 2 )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter,

        [Parameter()]
        [string]$BaseFilter,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string[]]$SecurityMask = 'None',

        [Parameter()]
        [bool]$TombStone,

        [Parameter()]
        [bool]$IncludeAllProperties,

        [Parameter()]
        [bool]$IncludeNullProperties,

        [Parameter()]
        [bool]$ChangeLogicOrder,

        [Parameter()]
        $ModifiedAfter,

        [Parameter()]
        $ModifiedBefore,

        [Parameter()]
        $CreatedAfter,

        [Parameter()]
        $CreatedBefore,

        [Parameter()]
        [bool]$LiteralFilter
    )

    # Function initialization
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    # Generate additional groups of filters to add to the LDAP filter set
    #  these will always be logically ANDed with the custom filters
    $LDAPFilters = @()

    if ($ChangeLogicOrder) {
        Write-Verbose "$($FunctionName): Setting logic order for custom filters to OR."
        $AndOr = '|'
    }
    else {
        Write-Verbose "$($FunctionName): Setting logic order for custom filters to AND."
        $AndOr = '&'
    }

    $LDAPFilters += Get-CombinedLDAPFilter -Filter $Filter -Conditional $AndOr

    # Create a set of other filters based on the passed parameters
    $ModifiedFilters = @()

    # Filter for modification time
    if ($ModifiedAfter) {
        $ModifiedFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
    }
    if ($ModifiedBefore) {
        $ModifiedFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
    }

    $LDAPFilters += Get-CombinedLDAPFilter -Filter $ModifiedFilters -Conditional '&'

    # Filter for creation time
    $CreatedFilters = @()
    if ($CreatedAfter) {
        $CreatedFilters += "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
    }
    if ($CreatedBefore) {
        $CreatedFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
    }
    $LDAPFilters += Get-CombinedLDAPFilter -Filter $CreatedFilters -Conditional '&'

    if (-not [string]::IsNullOrEmpty($Identity)) {
        Write-Verbose "$($FunctionName): Identity was passed ($Identity), creating filter"

        $LDAPFilters += Get-CommonIDLDAPFilter -Identity $Identity -Filter $Filter -LiteralFilter $LiteralFilter
    }

    $LDAPFilters += $BaseFilter

    $FinalLDAPFilters = Get-CombinedLDAPFilter -Filter $LDAPFilters -Conditional '&'

    if ($null -eq $FinalLDAPFilters) {
        $FinalLDAPFilters = '(distinguishedName=*)'
    }
    Write-Verbose "$($FunctionName): Final LDAPFilter string = $FinalLDAPFilters"

    $SearcherParams = @{
        ComputerName = $ComputerName
        SearchRoot = $searchRoot
        SearchScope = $SearchScope
        Limit = $Limit
        Credential = $Credential
        Filter = $FinalLDAPFilters
        Properties = $Properties
        PageSize = $PageSize
        SecurityMask = $SecurityMask
    }
    if ($Tombstone) {
        Write-Verbose "$($FunctionName): Including tombstone items"
        $SearcherParams.Tombstone = $true
    }

    # If all properties are being returned then we have nothing more to do
    if ($IncludeAllProperties) {
        Write-Verbose "$($FunctionName): Including all properties"
        $SearcherParams.Properties = '*'
    }
    else {

        # Otherwise we need to maybe add different properties which are used to derive other properties
        if ($IncludeNullProperties) {
            Write-Verbose "$($FunctionName): Including null properties"
            # To derive null properties we need the objectClass for the schema lookup.
            if (($SearcherParams.Properties -notcontains 'objectClass') -and ($SearcherParams.Properties -ne '*')) {
                $SearcherParams.Properties += 'objectClass'
            }
        }

        # if we are including some non-standard group properties then add grouptype so we can derive them
        if (($SearcherParams.Properties -contains 'GroupScope') -or ($SearcherParams.Properties -contains 'GroupCategory')) {
            if ($SearcherParams.Properties -notcontains 'grouptype') {
                $SearcherParams.Properties += 'grouptype'
            }
        }
    }

    Write-Verbose "$($FunctionName): $(New-Object psobject -Property $SearcherParams)"
    return $SearcherParams
}


function Get-CredentialState {
    <#
    .SYNOPSIS
    Returns the type of connection you have based on what is passed.

    .DESCRIPTION
    Returns the type of connection you have based on what is passed.

    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.

    .PARAMETER Credential
    The credential to enumerate.

    .EXAMPLE
    PS C:\> Get-Credential $null
    Returns the current user settings. Password will be returned as $null.

    .NOTES
    Author: Zachary Loeber

    .LINK
    https://www.the-little-things.net
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $CurrCreds = Split-Credential -Credential $Credential

    if ( $CurrCreds.AltUser -and (-not [string]::IsNullOrEmpty($ComputerName)) ) {
        return 'AltUserAndServer'
    }
    elseif ($CurrCreds.AltUser) {
        return 'AltUser'
    }
    elseif (-not [string]::IsNullOrEmpty($ComputerName)) {
        return 'CurrentUserAltServer'
    }
    else {
        return 'CurrentUser'
    }
}


function Get-DecryptedCpassword {
    [CmdletBinding()]
    Param (
        [string]$Cpassword
    )

    try {
        #Append appropriate padding based on string length
        $Mod = ($Cpassword.length % 4)

        switch ($Mod) {
        '1' {$Cpassword = $Cpassword.Substring(0,$Cpassword.Length -1)}
        '2' {$Cpassword += ('=' * (4 - $Mod))}
        '3' {$Cpassword += ('=' * (4 - $Mod))}
        }

        $Base64Decoded = [Convert]::FromBase64String($Cpassword)

        #Create a new AES .NET Crypto Object
        $AesObject = New-Object System.Security.Cryptography.AesCryptoServiceProvider
        [Byte[]] $AesKey = @(0x4e,0x99,0x06,0xe8,0xfc,0xb6,0x6c,0xc9,0xfa,0xf4,0x93,0x10,0x62,0x0f,0xfe,0xe8,
                                0xf4,0x96,0xe8,0x06,0xcc,0x05,0x79,0x90,0x20,0x9b,0x09,0xa4,0x33,0xb6,0x6c,0x1b)

        #Set IV to all nulls to prevent dynamic generation of IV value
        $AesIV = New-Object Byte[]($AesObject.IV.Length)
        $AesObject.IV = $AesIV
        $AesObject.Key = $AesKey
        $DecryptorObject = $AesObject.CreateDecryptor()
        [Byte[]] $OutBlock = $DecryptorObject.TransformFinalBlock($Base64Decoded, 0, $Base64Decoded.length)

        return [System.Text.UnicodeEncoding]::Unicode.GetString($OutBlock)
    }

    catch {
        Write-Error $Error[0]
    }
}

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

function Get-GUIDMap {
    <#
    .SYNOPSIS
    Helper to build a hash table of [GUID] -> resolved names
    .DESCRIPTION
    Helper to build a hash table of [GUID] -> resolved names. Heavily adapted from http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx
    .PARAMETER ComputerName
    Fully Qualified Name of a remote domain controller to connect to.
    .PARAMETER Credential
    Alternate credentials for retrieving domain information.
    .PARAMETER Domain
    Domain name to retreive the GUID mapping for.
    .PARAMETER Force
    Force Update the domain GUID mapping
    .EXAMPLE
    NA
    .NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name','Identity')]
        [string]$Forest = ($Script:CurrentForest).name,

        [Parameter( Position = 1 )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position = 2 )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter( Position = 3 )]
        [switch]$Force
    )

    Begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        if ([string]::IsNullOrEmpty($Forest)) {
            $Forest = (Get-DSdomain).Forest.Name
            Write-Verbose "$($FunctionName): No domain passed, searching $Forest"
        }
    }
    End {
        if ((-not $Script:GUIDMap.ContainsKey($Forest)) -or $Force) {
            $GUIDs = @{'00000000-0000-0000-0000-000000000000' = 'All'}

            $ForestSchemaPath = (Get-DSSchema -ComputerName $ComputerName -ForestName $Forest -Credential $Credential).Name

            Write-Verbose "$($FunctionName): Retreiving all the Schema GUID IDs in the $ForestSchemaPath, This could take quite a while..."
            Get-DSObject -SearchRoot $ForestSchemaPath -Filter '(schemaIDGUID=*)' -ComputerName $ComputerName -Credential $Credential -ResultsAs directoryentry | Foreach {
                $GUIDs[(New-Object Guid (,$_.properties.schemaidguid[0])).Guid] = $_.properties.name[0]
            }

            $RightsPath = $ForestSchemaPath -replace "Schema", "Extended-Rights"
            Write-Verbose "$($FunctionName): Retreiving all the Schema GUID IDs in the $RightsPath, This could take quite a while..."
            Get-DSObject -SearchRoot $RightsPath -Filter 'objectClass=controlAccessRight' -ComputerName $ComputerName -Credential $Credential -ResultsAs directoryentry | Foreach {
                $GUIDs[$_.properties.rightsguid[0].toString()] = $_.properties.name[0]
            }

            $Script:GUIDMap[$Forest] = $GUIDs
        }
        else {
            Write-Verbose "$($FunctionName): $Forest already exists in GUIDMap, skipping."
        }
    }
}


function New-DynamicParameter {
    <#
    .SYNOPSIS
    Helper function to simplify creating dynamic parameters

    .DESCRIPTION
    Helper function to simplify creating dynamic parameters.

    Example use cases:
        Include parameters only if your environment dictates it
        Include parameters depending on the value of a user-specified parameter
        Provide tab completion and intellisense for parameters, depending on the environment

    Please keep in mind that all dynamic parameters you create, will not have corresponding variables created.
        Use New-DynamicParameter with 'CreateVariables' switch in your main code block,
        ('Process' for advanced functions) to create those variables.
        Alternatively, manually reference $PSBoundParameters for the dynamic parameter value.

    This function has two operating modes:

    1. All dynamic parameters created in one pass using pipeline input to the function. This mode allows to create dynamic parameters en masse,
    with one function call. There is no need to create and maintain custom RuntimeDefinedParameterDictionary.

    2. Dynamic parameters are created by separate function calls and added to the RuntimeDefinedParameterDictionary you created beforehand.
    Then you output this RuntimeDefinedParameterDictionary to the pipeline. This allows more fine-grained control of the dynamic parameters,
    with custom conditions and so on.

    .NOTES
    Credits to jrich523 and ramblingcookiemonster for their initial code and inspiration:
        https://github.com/RamblingCookieMonster/PowerShell/blob/master/New-DynamicParam.ps1
        http://ramblingcookiemonster.wordpress.com/2014/11/27/quick-hits-credentials-and-dynamic-parameters/
        http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/

    Credit to BM for alias and type parameters and their handling

    .PARAMETER Name
    Name of the dynamic parameter

    .PARAMETER Type
    Type for the dynamic parameter.  Default is string

    .PARAMETER Alias
    If specified, one or more aliases to assign to the dynamic parameter

    .PARAMETER Mandatory
    If specified, set the Mandatory attribute for this dynamic parameter

    .PARAMETER Position
    If specified, set the Position attribute for this dynamic parameter

    .PARAMETER HelpMessage
    If specified, set the HelpMessage for this dynamic parameter

    .PARAMETER DontShow
    If specified, set the DontShow for this dynamic parameter.
    This is the new PowerShell 4.0 attribute that hides parameter from tab-completion.
    http://www.powershellmagazine.com/2013/07/29/pstip-hiding-parameters-from-tab-completion/

    .PARAMETER ValueFromPipeline
    If specified, set the ValueFromPipeline attribute for this dynamic parameter

    .PARAMETER ValueFromPipelineByPropertyName
    If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter

    .PARAMETER ValueFromRemainingArguments
    If specified, set the ValueFromRemainingArguments attribute for this dynamic parameter

    .PARAMETER ParameterSetName
    If specified, set the ParameterSet attribute for this dynamic parameter. By default parameter is added to all parameters sets.

    .PARAMETER AllowNull
    If specified, set the AllowNull attribute of this dynamic parameter

    .PARAMETER AllowEmptyString
    If specified, set the AllowEmptyString attribute of this dynamic parameter

    .PARAMETER AllowEmptyCollection
    If specified, set the AllowEmptyCollection attribute of this dynamic parameter

    .PARAMETER ValidateNotNull
    If specified, set the ValidateNotNull attribute of this dynamic parameter

    .PARAMETER ValidateNotNullOrEmpty
    If specified, set the ValidateNotNullOrEmpty attribute of this dynamic parameter

    .PARAMETER ValidateRange
    If specified, set the ValidateRange attribute of this dynamic parameter

    .PARAMETER ValidateLength
    If specified, set the ValidateLength attribute of this dynamic parameter

    .PARAMETER ValidatePattern
    If specified, set the ValidatePattern attribute of this dynamic parameter

    .PARAMETER ValidateScript
    If specified, set the ValidateScript attribute of this dynamic parameter

    .PARAMETER ValidateSet
    If specified, set the ValidateSet attribute of this dynamic parameter

    .PARAMETER Dictionary
    If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary.
    Appropriate for custom dynamic parameters creation.

    If not specified, create and return a RuntimeDefinedParameterDictionary
    Aappropriate for a simple dynamic parameter creation.

    .EXAMPLE
    Create one dynamic parameter.

    This example illustrates the use of New-DynamicParameter to create a single dynamic parameter.
    The Drive's parameter ValidateSet is populated with all available volumes on the computer for handy tab completion / intellisense.

    Usage: Get-FreeSpace -Drive <tab>

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            # Get drive names for ValidateSet attribute
            $DriveList = ([System.IO.DriveInfo]::GetDrives()).Name

            # Create new dynamic parameter
            New-DynamicParameter -Name Drive -ValidateSet $DriveList -Type ([array]) -Position 0 -Mandatory
        }

        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object {$Drive -contains $_.Name}
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }

    .EXAMPLE
    Create several dynamic parameters not using custom RuntimeDefinedParameterDictionary (requires piping).

    In this example two dynamic parameters are created. Each parameter belongs to the different parameter set, so they are mutually exclusive.

    The Drive's parameter ValidateSet is populated with all available volumes on the computer.
    The DriveType's parameter ValidateSet is populated with all available drive types.

    Usage: Get-FreeSpace -Drive <tab>
        or
    Usage: Get-FreeSpace -DriveType <tab>

    Parameters are defined in the array of hashtables, which is then piped through the New-Object to create PSObject and pass it to the New-DynamicParameter function.
    Because of piping, New-DynamicParameter function is able to create all parameters at once, thus eliminating need for you to create and pass external RuntimeDefinedParameterDictionary to it.

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            # Array of hashtables that hold values for dynamic parameters
            $DynamicParameters = @(
                @{
                    Name = 'Drive'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
                    ParameterSetName = 'Drive'
                },
                @{
                    Name = 'DriveType'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
                    ParameterSetName = 'DriveType'
                }
            )

            # Convert hashtables to PSObjects and pipe them to the New-DynamicParameter,
            # to create all dynamic paramters in one function call.
            $DynamicParameters | ForEach-Object {New-Object PSObject -Property $_} | New-DynamicParameter
        }
        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            if($Drive)
            {
                $Filter = {$Drive -contains $_.Name}
            }
            elseif($DriveType)
            {
                $Filter =  {$DriveType -contains  $_.DriveType}
            }

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }

    .EXAMPLE
    Create several dynamic parameters, with multiple Parameter Sets, not using custom RuntimeDefinedParameterDictionary (requires piping).

    In this example three dynamic parameters are created. Two of the parameters are belong to the different parameter set, so they are mutually exclusive.
    One of the parameters belongs to both parameter sets.

    The Drive's parameter ValidateSet is populated with all available volumes on the computer.
    The DriveType's parameter ValidateSet is populated with all available drive types.
    The DriveType's parameter ValidateSet is populated with all available drive types.
    The Precision's parameter controls number of digits after decimal separator for Free Space percentage.

    Usage: Get-FreeSpace -Drive <tab> -Precision 2
        or
    Usage: Get-FreeSpace -DriveType <tab> -Precision 2

    Parameters are defined in the array of hashtables, which is then piped through the New-Object to create PSObject and pass it to the New-DynamicParameter function.
    If parameter with the same name already exist in the RuntimeDefinedParameterDictionary, a new Parameter Set is added to it.
    Because of piping, New-DynamicParameter function is able to create all parameters at once, thus eliminating need for you to create and pass external RuntimeDefinedParameterDictionary to it.

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            # Array of hashtables that hold values for dynamic parameters
            $DynamicParameters = @(
                @{
                    Name = 'Drive'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
                    ParameterSetName = 'Drive'
                },
                @{
                    Name = 'DriveType'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
                    ParameterSetName = 'DriveType'
                },
                @{
                    Name = 'Precision'
                    Type = [int]
                    # This will add a Drive parameter set to the parameter
                    Position = 1
                    ParameterSetName = 'Drive'
                },
                @{
                    Name = 'Precision'
                    # Because the parameter already exits in the RuntimeDefinedParameterDictionary,
                    # this will add a DriveType parameter set to the parameter.
                    Position = 1
                    ParameterSetName = 'DriveType'
                }
            )

            # Convert hashtables to PSObjects and pipe them to the New-DynamicParameter,
            # to create all dynamic paramters in one function call.
            $DynamicParameters | ForEach-Object {New-Object PSObject -Property $_} | New-DynamicParameter
        }
        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            if($Drive)
            {
                $Filter = {$Drive -contains $_.Name}
            }
            elseif($DriveType)
            {
                $Filter = {$DriveType -contains  $_.DriveType}
            }

            if(!$Precision)
            {
                $Precision = 2
            }

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), $Precision)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }

    .Example
    Create dynamic parameters using custom dictionary.

    In case you need more control, use custom dictionary to precisely choose what dynamic parameters to create and when.
    The example below will create DriveType dynamic parameter only if today is not a Friday:

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            $Drive = @{
                Name = 'Drive'
                Type = [array]
                Position = 0
                Mandatory = $true
                ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
                ParameterSetName = 'Drive'
            }

            $DriveType =  @{
                Name = 'DriveType'
                Type = [array]
                Position = 0
                Mandatory = $true
                ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
                ParameterSetName = 'DriveType'
            }

            # Create dictionary
            $DynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Add new dynamic parameter to dictionary
            New-DynamicParameter @Drive -Dictionary $DynamicParameters

            # Add another dynamic parameter to dictionary, only if today is not a Friday
            if((Get-Date).DayOfWeek -ne [DayOfWeek]::Friday)
            {
                New-DynamicParameter @DriveType -Dictionary $DynamicParameters
            }

            # Return dictionary with dynamic parameters
            $DynamicParameters
        }
        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            if($Drive)
            {
                $Filter = {$Drive -contains $_.Name}
            }
            elseif($DriveType)
            {
                $Filter =  {$DriveType -contains  $_.DriveType}
            }

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }
    #>
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'DynamicParameter')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [System.Type]$Type = [int],

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [string[]]$Alias,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$Mandatory,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [int]$Position,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [string]$HelpMessage,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$DontShow,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValueFromPipeline,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValueFromPipelineByPropertyName,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValueFromRemainingArguments,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [string]$ParameterSetName = '__AllParameterSets',

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$AllowNull,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$AllowEmptyString,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$AllowEmptyCollection,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValidateNotNull,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValidateNotNullOrEmpty,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateCount(2, 2)]
        [int[]]$ValidateCount,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateCount(2, 2)]
        [int[]]$ValidateRange,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateCount(2, 2)]
        [int[]]$ValidateLength,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [string]$ValidatePattern,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [scriptblock]$ValidateScript,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ValidateSet,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (!($_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary])) {
                    Throw 'Dictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object'
                }
                $true
            })]
        $Dictionary = $false,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
        [switch]$CreateVariables,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                # System.Management.Automation.PSBoundParametersDictionary is an internal sealed class,
                # so one can't use PowerShell's '-is' operator to validate type.
                if ($_.GetType().Name -ne 'PSBoundParametersDictionary') {
                    Throw 'BoundParameters must be a System.Management.Automation.PSBoundParametersDictionary object'
                }
                $true
            })]
        $BoundParameters
    )

    Begin {
        Write-Verbose 'Creating new dynamic parameters dictionary'
        $InternalDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        Write-Verbose 'Getting common parameters'
        function _temp { [CmdletBinding()] Param() }
        $CommonParameters = (Get-Command _temp).Parameters.Keys
    }

    Process {
        if ($CreateVariables) {
            Write-Verbose 'Creating variables from bound parameters'
            Write-Debug 'Picking out bound parameters that are not in common parameters set'
            $BoundKeys = $BoundParameters.Keys | Where-Object { $CommonParameters -notcontains $_ }

            foreach ($Parameter in $BoundKeys) {
                Write-Debug "Setting existing variable for dynamic parameter '$Parameter' with value '$($BoundParameters.$Parameter)'"
                Set-Variable -Name $Parameter -Value $BoundParameters.$Parameter -Scope 1 -Force
            }
        }
        else {
            Write-Verbose 'Looking for cached bound parameters'
            Write-Debug 'More info: https://beatcracker.wordpress.com/2014/12/18/psboundparameters-pipeline-and-the-valuefrompipelinebypropertyname-parameter-attribute'
            $StaleKeys = @()
            $StaleKeys = $PSBoundParameters.GetEnumerator() |
                ForEach-Object {
                if ($_.Value.PSobject.Methods.Name -match '^Equals$') {
                    # If object has Equals, compare bound key and variable using it
                    if (!$_.Value.Equals((Get-Variable -Name $_.Key -ValueOnly -Scope 0))) {
                        $_.Key
                    }
                }
                else {
                    # If object doesn't has Equals (e.g. $null), fallback to the PowerShell's -ne operator
                    if ($_.Value -ne (Get-Variable -Name $_.Key -ValueOnly -Scope 0)) {
                        $_.Key
                    }
                }
            }
            if ($StaleKeys) {
                [string[]]"Found $($StaleKeys.Count) cached bound parameters:" + $StaleKeys | Write-Debug
                Write-Verbose 'Removing cached bound parameters'
                $StaleKeys | ForEach-Object {[void]$PSBoundParameters.Remove($_)}
            }

            # Since we rely solely on $PSBoundParameters, we don't have access to default values for unbound parameters
            Write-Verbose 'Looking for unbound parameters with default values'

            Write-Debug 'Getting unbound parameters list'
            $UnboundParameters = (Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters.GetEnumerator()  |
                # Find parameters that are belong to the current parameter set
            Where-Object { $_.Value.ParameterSets.Keys -contains $PsCmdlet.ParameterSetName } |
                Select-Object -ExpandProperty Key |
                # Find unbound parameters in the current parameter set
												Where-Object { $PSBoundParameters.Keys -notcontains $_ }

            # Even if parameter is not bound, corresponding variable is created with parameter's default value (if specified)
            Write-Debug 'Trying to get variables with default parameter value and create a new bound parameter''s'
            $tmp = $null
            foreach ($Parameter in $UnboundParameters) {
                $DefaultValue = Get-Variable -Name $Parameter -ValueOnly -Scope 0
                if (!$PSBoundParameters.TryGetValue($Parameter, [ref]$tmp) -and $DefaultValue) {
                    $PSBoundParameters.$Parameter = $DefaultValue
                    Write-Debug "Added new parameter '$Parameter' with value '$DefaultValue'"
                }
            }

            if ($Dictionary) {
                Write-Verbose 'Using external dynamic parameter dictionary'
                $DPDictionary = $Dictionary
            }
            else {
                Write-Verbose 'Using internal dynamic parameter dictionary'
                $DPDictionary = $InternalDictionary
            }

            Write-Verbose "Creating new dynamic parameter: $Name"

            # Shortcut for getting local variables
            $GetVar = {Get-Variable -Name $_ -ValueOnly -Scope 0}

            # Strings to match attributes and validation arguments
            $AttributeRegex = '^(Mandatory|Position|ParameterSetName|DontShow|HelpMessage|ValueFromPipeline|ValueFromPipelineByPropertyName|ValueFromRemainingArguments)$'
            $ValidationRegex = '^(AllowNull|AllowEmptyString|AllowEmptyCollection|ValidateCount|ValidateLength|ValidatePattern|ValidateRange|ValidateScript|ValidateSet|ValidateNotNull|ValidateNotNullOrEmpty)$'
            $AliasRegex = '^Alias$'

            Write-Debug 'Creating new parameter''s attirubutes object'
            $ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute

            Write-Debug 'Looping through the bound parameters, setting attirubutes...'
            switch -regex ($PSBoundParameters.Keys) {
                $AttributeRegex {
                    Try {
                        $ParameterAttribute.$_ = . $GetVar
                        Write-Debug "Added new parameter attribute: $_"
                    }
                    Catch {
                        $_
                    }
                    continue
                }
            }

            if ($DPDictionary.Keys -contains $Name) {
                Write-Verbose "Dynamic parameter '$Name' already exist, adding another parameter set to it"
                $DPDictionary.$Name.Attributes.Add($ParameterAttribute)
            }
            else {
                Write-Verbose "Dynamic parameter '$Name' doesn't exist, creating"

                Write-Debug 'Creating new attribute collection object'
                $AttributeCollection = New-Object -TypeName Collections.ObjectModel.Collection[System.Attribute]

                Write-Debug 'Looping through bound parameters, adding attributes'
                switch -regex ($PSBoundParameters.Keys) {
                    $ValidationRegex {
                        Try {
                            $ParameterOptions = New-Object -TypeName "System.Management.Automation.${_}Attribute" -ArgumentList (. $GetVar) -ErrorAction Stop
                            $AttributeCollection.Add($ParameterOptions)
                            Write-Debug "Added attribute: $_"
                        }
                        Catch {
                            $_
                        }
                        continue
                    }

                    $AliasRegex {
                        Try {
                            $ParameterAlias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList (. $GetVar) -ErrorAction Stop
                            $AttributeCollection.Add($ParameterAlias)
                            Write-Debug "Added alias: $_"
                            continue
                        }
                        Catch {
                            $_
                        }
                    }
                }

                Write-Debug 'Adding attributes to the attribute collection'
                $AttributeCollection.Add($ParameterAttribute)

                Write-Debug 'Finishing creation of the new dynamic parameter'
                $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)

                Write-Debug 'Adding dynamic parameter to the dynamic parameter dictionary'
                $DPDictionary.Add($Name, $Parameter)
            }
        }
    }

    End {
        if (!$CreateVariables -and !$Dictionary) {
            Write-Verbose 'Writing dynamic parameter dictionary to the pipeline'
            $DPDictionary
        }
    }
}

Function New-ProxyFunction {
    <#
    .SYNOPSIS
        Proxy function dynamic parameter block
    .DESCRIPTION
        The dynamic parameter block of a proxy function. This block can be used to copy a proxy function target's parameters, regardless of changes from version to version.
    #>
    [System.Diagnostics.DebuggerStepThrough()]
    param(
        # The name of the command being proxied.
        [System.String]
        $CommandName,

        # The type of the command being proxied. Valid values include 'Cmdlet' or 'Function'.
        [System.Management.Automation.CommandTypes]
        $CommandType
    )
    try {
        # Look up the command being proxied.
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand($CommandName, $CommandType)

        #If the command was not found, throw an appropriate command not found exception.
        if (-not $wrappedCmd) {
            $PSCmdlet.ThrowCommandNotFoundError($CommandName, $PSCmdlet.MyInvocation.MyCommand.Name)
        }

        # Lookup the command metadata.
        $metadata = New-Object -TypeName System.Management.Automation.CommandMetadata -ArgumentList $wrappedCmd

        # Create dynamic parameters, one for each parameter on the command being proxied.
        $dynamicDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        foreach ($key in $metadata.Parameters.Keys) {
            $parameter = $metadata.Parameters[$key]
            $dynamicParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @(
                $parameter.Name
                $parameter.ParameterType
                ,$parameter.Attributes
            )
            $dynamicDictionary.Add($parameter.Name, $dynamicParameter)
        }
        $dynamicDictionary

    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Split-Credential {
    <#
    .SYNOPSIS
    Enumerates the username, password, and domain of a credential object.

    .DESCRIPTION
    Enumerates the username, password, and domain of a credential object.

    .PARAMETER Credential
    The credential to enumerate.

    .EXAMPLE
    PS C:\> Split-Credential $null
    Returns the current user settings. Password will be returned as $null.

    .NOTES
    Author: Zachary Loeber

    .LINK
    https://www.the-little-things.net
    #>
    [CmdletBinding()]
    param (
        [parameter()]
        [alias('Cred','Creds')]
        [System.Management.Automation.PSCredential]$Credential
    )
    if ($Script:ThisModuleLoaded) {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $SplitCreds = @{
        UserName = $null
        Password = $null
        Domain = $null
        AltUser = $true
    }

    if ($Credential -eq $null) {
        if ((Get-DomainJoinStatus) -eq 'Domain') {
            Write-Verbose "$($FunctionName): No credential passed trying to use the local user instead"
            $SplitCreds.Domain,$SplitCreds.UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -split "\\"
            $SplitCreds.AltUser = $false
        }
        else {
            throw "$($FunctionName): No credentials passed and this system is not domain joined."
        }
    }
    else {
        Write-Verbose "$($FunctionName): Credential passed, splitting it up to its component parts."
        $SplitCreds.UserName= $Credential.GetNetworkCredential().UserName.ToString()
        $SplitCreds.Password = $Credential.GetNetworkCredential().Password.ToString()
        $SplitCreds.Domain = $Credential.GetNetworkCredential().Domain.ToString()
    }
    if ($SplitCreds.Domain -eq '') {
        Write-Verbose "$($FunctionName): Credential passed without a domain, looking for a forest name instead (@forest.com).."
        $SplitCreds.UserName,$SplitCreds.Domain = $SplitCreds.UserName -split "\@"
        if ($SplitCreds.Domain -eq $null) {
            Write-Verbose "$($FunctionName): Credential passed without a domain or forest name. Attempting to use current user's domain instead"
            $SplitCreds.Domain,$null = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name -split "\\"
            if ($SplitCreds.Domain -eq '') {
                Write-Verbose "$($FunctionName): Credential passed without a domain or forest name."
                $SplitCreds.Domain = $null
            }
        }
    }

    $SplitCreds
}


## PUBLIC MODULE FUNCTIONS AND DATA ##

function Add-DSGroupMember {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Add-DSGroupMember.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [Alias('GroupName')]
        [string]$Group,

        [Parameter(HelpMessage = 'Force add group membership.')]
        [Switch]$Force
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()
        $YesToAll = $false
        $NoToAll = $false
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'DirectoryEntry'
            Identity = $Group
        }

        try {
            # Otherwise get a DE of the group for later
            Write-Verbose "$($FunctionName): Retreiving directory entry of the group - $Group"
            $GroupDE = @(Get-DSGroup @SearcherParams)
        }
        catch {
            throw "Unable to get a directory entry for the specified group of $Group"
        }

        if ($GroupDE.Count -gt 1) {
            throw "More than one group result was found for $Group, exiting!"
        }
        else {
            $GroupDE = $GroupDE[0]
        }

        $GetObjectParams.Properties = 'adspath','name'

        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | ForEach-Object {
                $Name = $_.name
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Add $Name to $Group", "Add $Name from $Group?","Adding $Name from $Group")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to add '$Name' to '$Group'?", "Adding $Name from $Group", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            $GroupDE.Add($_.adspath)
                        }
                        catch {
                            $ThisError = $_
                            Write-Warning "$($FunctionName): Unable to add $Name to $Group"
                        }
                    }
                }
            }
        }
    }
}



Function Add-DSTranslatedUAC {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Add-DSTranslatedUAC.md
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


function Connect-DSAD {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Connect-DSAD.md
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName,
        
        [parameter(Position=1)]
        [alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    # Update the module variables
    $Script:CurrentDomain = $null
    $Script:CurrentForest = $null
    $Script:CurrentBaseDN = $null
    $Script:CurrentCredential = $Credential
    $Script:CurrentServer = $ComputerName

    $CurrCreds = Split-Credential -Credential $Credential
    
    Write-Verbose "$($FunctionName): Using Domain = $($CurrCreds.Domain); UserName = $($CurrCreds.UserName)"

    switch ((Get-CredentialState -Credential $Credential -ComputerName $ComputerName) ) {
        'AltUserAndServer' {
            # When connecting with alternate credentials we first connect to the AD and Directory contexts to then get our forest and domain objects setup
            Write-Verbose "$($FunctionName): Attempting to connect with alternate credentials to $ComputerName"
            $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext 'DirectoryServer', $ComputerName, $CurrCreds.UserName, $CurrCreds.Password
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        'AltUser' {
            # When connecting with alternate credentials without a server name we first try to locate an acceptable DC as connecting to a DC can expose both domain and forest info
            Write-Verbose "$($FunctionName): Attempting to connect with alternate credentials by first locating a DC to connect to."
            $DCContext = Get-DSDirectoryContext -Credential $Credential -ContextType 'Domain' -ContextName $CurrCreds.Domain
            $ComputerName = ([System.DirectoryServices.ActiveDirectory.DomainController]::findOne($DCContext)).Name
            $Script:CurrentServer = $ComputerName
            
            Write-Verbose "$($FunctionName): Connecting to $ComputerName"
            $ADContext = Get-DSDirectoryContext -Credential $Credential -ContextType 'DirectoryServer' -ContextName $ComputerName
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        'CurrentUserAltServer' {
            # We are using the current user but connecting to a different server
            Write-Verbose "$($FunctionName): Attempting to connect with current credentials to $ComputerName"
            $ADContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext 'DirectoryServer', $ComputerName
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ADContext)
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ADContext)
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        'CurrentUser' {
            # Using current credentials we first gather the current forest and domain information and then create the contexts
            Write-Verbose "$($FunctionName): Attempting to connect as the current user to the current domain"
            $Script:CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $Script:CurrentDomain =  [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $Script:CurrentBaseDN = "LDAP://$(($Script:CurrentDomain).Name)"
        }
        Default {
            Write-Error "$($FunctionName): Unable to connect to AD!"
        }
    }
}



function Convert-DSCSE {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Convert-DSCSE.md
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$CSEString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    $CSEString = $CSEString -replace '}{','},{'
    ($Script:GPOGuidRef).keys | Foreach-Object {
        $CSEString = $CSEString -replace $_,$GPOGuidRef[$_]
    }

    $CSEString
}



Function Convert-DSName {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Convert-DSName.md
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



function Convert-DSUACProperty {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Convert-DSUACProperty.md
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$UACProperty
    )
    if ($Script:ThisModuleLoaded) {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."
    try {
        $UAC = [Enum]::Parse('userAccountControlFlags', $UACProperty)
        $Script:UACAttribs | Foreach-Object {
            if ($UAC -match $_) {
                $_
            }
        }
    }
    catch {
        Write-Warning -Message ("$($FunctionName) {0}" -f $_.Exception.Message)
    }
}



function Disable-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Disable-DSObject.md
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium' )]
    param(
        [Parameter(Position = 0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string]$Identity,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(Position = 3)]
        [Switch]$Force
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'searcher'
            Properties = @('name','adspath','distinguishedname','useraccountcontrol')
        }

        $YesToAll = $false
        $NoToAll = $false
    }
    process {
        $SearcherParams.Identity = $Identity
        $Identities += Get-DSObject @SearcherParams
    }
    end {
        Foreach ($ID in $Identities) {
            $Name = $ID.Properties['name']
            Write-Verbose "$($FunctionName): Start disable object processing for object - $Name"

            if ($ID.properties.Contains('useraccountcontrol')) {
                $UAC = Convert-DSUACProperty -UACProperty ($ID.properties)['useraccountcontrol']
                if ( $UAC -notcontains 'ACCOUNTDISABLE' ) {
                    Write-Verbose "$($FunctionName): Enabling object name: $Name"
                    if ($pscmdlet.ShouldProcess("Disable $Name?", "Disable $Name?","Enabling $Name")) {
                        if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to disable '$Name'?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                            try {
                                #$ID.Put($Property,$Value)
                                $DE = $ID.GetDirectoryEntry()
                                $DE.psbase.InvokeSet('AccountDisabled', $true)
                                $DE.SetInfo()
                            }
                            catch {
                                Write-Warning "$($FunctionName): Unable to disable $Name!"
                            }
                        }
                    }
                }
                else {
                    Write-Warning "$($FunctionName): $Name is already disabled"
                }
            }
            else {
                Write-Warning "$($FunctionName): $Name is an account object that can not be disabled."
            }
        }
    }
}



function Enable-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Enable-DSObject.md
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium' )]
    param(
        [Parameter(Position = 0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('sAMAccountName', 'distinguishedName')]
        [string]$Identity,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(Position = 3)]
        [Switch]$Force
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'searcher'
            Properties = @('name','adspath','distinguishedname','useraccountcontrol')
        }

        $YesToAll = $false
        $NoToAll = $false
    }
    process {
        $SearcherParams.Identity = $Identity
        $Identities += Get-DSObject @SearcherParams
    }
    end {
        Foreach ($ID in $Identities) {
            $Name = $ID.Properties['name']
            Write-Verbose "$($FunctionName): Start enable object processing for object - $Name"

            if ($ID.properties.Contains('useraccountcontrol')) {
                $UAC = Convert-DSUACProperty -UACProperty ($ID.properties)['useraccountcontrol']
                if ( $UAC -contains 'ACCOUNTDISABLE' ) {
                    Write-Verbose "$($FunctionName): Enabling object name: $Name"
                    if ($pscmdlet.ShouldProcess("Enable $Name?", "Enable $Name?","Enabling $Name")) {
                        if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to enable '$Name'?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                            try {
                                #$ID.Put($Property,$Value)
                                $DE = $ID.GetDirectoryEntry()
                                $DE.psbase.InvokeSet('AccountDisabled', $false)
                                $DE.SetInfo()
                            }
                            catch {
                                Write-Warning "$($FunctionName): Unable to enable $Name!"
                            }
                        }
                    }
                }
                else {
                    Write-Warning "$($FunctionName): $Name is already enabled"
                }
            }
            else {
                Write-Warning "$($FunctionName): $Name is an account object that can not be enabled."
            }
        }
    }
}



function Format-DSSearchFilterValue {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Format-DSSearchFilterValue.md
    #>
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true, ValueFromPipeline = $True )]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $SearchString = $SearchString.Replace('\', '\5c')
    $SearchString = $SearchString.Replace('*', '\2a')
    $SearchString = $SearchString.Replace('(', '\28')
    $SearchString = $SearchString.Replace(')', '\29')
    $SearchString = $SearchString.Replace('/', '\2f')
    $SearchString = $SearchString.Replace("`0", '\00')
    Write-Verbose "$($FunctionName): formatted search string = $SearchString"

    $SearchString
}



function Get-DSAccountMembership {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSAccountMembership.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [switch]$DotNotAllowDelegation,

        [Parameter()]
        [switch]$AllowDelegation,

        [Parameter()]
        [switch]$UnconstrainedDelegation,

        [Parameter()]
        [datetime]$LogOnAfter,

        [Parameter()]
        [datetime]$LogOnBefore,

        [Parameter()]
        [switch]$NoPasswordRequired,

        [Parameter()]
        [switch]$PasswordNeverExpires,

        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [switch]$Enabled,

        [Parameter()]
        [switch]$AdminCount,

        [Parameter()]
        [switch]$ServiceAccount,

        [Parameter()]
        [switch]$MustChangePassword,

        [Parameter()]
        [switch]$Locked
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }

        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Most efficient user ldap filter for user accounts: http://www.selfadsi.org/extended-ad/search-user-accounts.htm
        $BaseFilters = @('sAMAccountType=805306368')

        # Logon LDAP filter section
        $LogonLDAPFilters = @()
        if ($LogOnAfter) {
            $LogonLDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
        }
        if ($LogOnBefore) {
            $LogonLDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
        }
        $BaseFilters += Get-CombinedLDAPFilter -Filter $LogonLDAPFilters -Conditional '&'

        # Filter for accounts that are marked as sensitive and can not be delegated.
        if ($DotNotAllowDelegation) {
            $BaseFilters += 'userAccountControl:1.2.840.113556.1.4.803:=1048574'
        }

        if ($AllowDelegation) {
            # negation of "Accounts that are sensitive and not trusted for delegation"
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=1048574)"
        }

        # User has unconstrained delegation set.
        if ($UnconstrainedDelegation) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        # Account is locked
        if ($Locked) {
            $BaseFilters += 'lockoutTime>=1'
        }

        # Filter for accounts who do not requiere a password to logon.
        if ($NoPasswordRequired) {
            $BaseFilters += 'userAccountControl:1.2.840.113556.1.4.803:=32'
        }

        # Filter for accounts whose password does not expires.
        if ($PasswordNeverExpires) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=65536"
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        # Filter for accounts that have SPN set.
        if ($ServiceAccount) {
            $BaseFilters += "servicePrincipalName=*"
        }

        # Filter whose users must change their passwords.
        if ($MustChangePassword) {
            $BaseFilters += 'pwdLastSet=0'
        }

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}



function Get-DSADSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSADSchemaVersion.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    process {
        $SchemaContext = (Get-DSSchema -ComputerName $ComputerName -Credential $Credential).name

        $objectVersion = (Get-DSObject -SearchScope:Base -SearchRoot $SchemaContext -Properties 'objectversion' -ComputerName $ComputerName -Credential $Credential).objectversion

        if (($Script:SchemaVersionTable).Keys -contains $objectVersion) {
            Write-Verbose "$($FunctionName): Exchange schema version found."
            $Script:SchemaVersionTable[$objectVersion]
        }
        else {
            Write-Verbose "$($FunctionName): Exchange schema version not in our list."
            $objectVersion
        }
    }
}


function Get-DSADSite {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSADSite.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [Alias('Name','Identity','ForestName')]
        [string]$Forest = ($Script:CurrentForest).name,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
    }

    end {
        try {
            (Get-DSForest -Identity $Forest @DSParams).Sites
        }
        catch {
            Write-Warning "$($FunctionName): Unable to get AD site information from the forest."
        }
    }
}



function Get-DSADSiteSubnet {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSADSiteSubnet.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [Alias('Name','Identity','ForestName')]
        [string]$Forest = ($Script:CurrentForest).name,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
    }

    end {
        try {
            ((Get-DSForest -Identity $Forest @DSParams).Sites).Subnets
        }
        catch {
            Write-Warning "$($FunctionName): Unable to get AD site information from the forest."
        }
    }
}



function Get-DSComputer {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSComputer.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(HelpMessage='AdminCount is greater than 0')]
        [switch]$AdminCount,

        [Parameter(HelpMessage='Only those trusted for delegation.')]
        [switch]$TrustedForDelegation,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnAfter,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnBefore,

        [Parameter(HelpMessage='Filter by the specified operating systems.')]
        [string[]]$OperatingSystem,

        [Parameter(HelpMessage='Computer is disabled')]
        [switch]$Disabled,

        [Parameter(HelpMessage='Computer is enabled')]
        [switch]$Enabled,

        [Parameter(HelpMessage='Filter by the specified Service Principal Names.')]
        [string[]]$SPN
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build our base filter (overwrites any dynamic parameter sent base filter)
        $BaseFilters = @('objectCategory=Computer')

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        # Filter for logon time
        if ($LogOnAfter) {
            $BaseFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
        }
        if ($LogOnBefore) {
            $BaseFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
        }

        # Filter by Operating System
        if ($OperatingSystem.Count -ge 1) {
            $BaseFilters += "|(operatingSystem={0})" -f ($OperatingSystem -join ')(operatingSystem=')
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter by Service Principal Name
        if ($SPN.Count -ge 1) {
            $BaseFilters += "|(servicePrincipalName={0})" -f ($SPN -join ')(servicePrincipalName=')
        }

        # Filter for hosts trusted for delegation.
        if ($TrustedForDelegation) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}



function Get-DSConfigPartition {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSConfigPartition.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }
    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

    }
    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }

        $GetDEParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSDirectoryEntryParameters -contains $_) } | Foreach-Object {
            $GetDEParams.$_ = $PSBoundParameters.$_
        }
        Write-Verbose "$($FunctionName): Directory Entry Search Parameters = $($GetDEParams)"
        $GetDEParams.DistinguishedName = 'rootDSE'

        try {
            $RootDSE = Get-DSDirectoryEntry @GetDEParams
            $GetObjectParams.SearchRoot = $rootDSE.configurationNamingContext
            $GetObjectParams.Identity = $Null
            $GetObjectParams.SearchScope = 'Base'
            $GetObjectParams.Properties = 'name','adspath','distinguishedname'

            Get-DSObject @GetObjectParams
        }
        catch {
            throw $_
        }
    }
}



function Get-DSCurrentConnectedDomain {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSCurrentConnectedDomain.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

   if ($Script:CurrentDomain -ne $null) {
       return $Script:CurrentDomain
   }
   else {
       try {
           Get-DSDomain -UpdateCurrent
           return $Script:CurrentDomain
       }
       catch {
           Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-ActiveDirectory first."
       }
   }
}



function Get-DSCurrentConnectedForest {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSCurrentConnectedForest.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    if ($Script:CurrentForest -ne $null) {
        return $Script:CurrentForest
    }
    else {
        try {
            Get-DSForest -UpdateCurrent
            return $Script:CurrentForest
        }
        catch {
            Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-ActiveDirectory first."
        }
    }
}



function Get-DSCurrentConnectedSchema {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSCurrentConnectedSchema.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    if ($Script:CurrentSchema -ne $null) {
        return $Script:CurrentSchema
    }
    else {
        try {
            Get-DSSchema -UpdateCurrent
            return $Script:CurrentSchema
        }
        catch {
            Write-Error "$($FunctionName): Not connected to Active Directory, you need to run Connect-DSAD first."
        }
    }
}



function Get-DSCurrentConnectionStatus {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSCurrentConnectionStatus.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

   if (($Script:CurrentDomain -ne $null) -and ($Script:CurrentForest -ne $null)) {
       return $True
   }
   else {
       return $False
   }
}



function Get-DSDFS {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSDFS.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $DSParams = @{
        ComputerName = $ComputerName
        Credential = $Credential
    }
    $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
    $DomNamingContext = $RootDSE.RootDomainNamingContext
    $DFSDN = "CN=Dfs-Configuration,CN=System,$DomNamingContext"

    if ((Test-DSObjectPath -Path $DFSDN @DSParams)) {
        # process fTDfs first
        $DFSData = @(Get-DSObject -SearchRoot $DFSDN @DSParams -Filter 'objectClass=fTDfs' -Properties Name,distinguishedName,remoteServerName)
        Foreach ($DFSItem in $DFSData) {
            $DomDFSProps = @{
                objectClass = 'fTDfs'
                distinguishedName = $DFSItem.distinguishedName
                name = $DFSItem.Name
                remoteServerName = $DFSItem.remoteServerName -replace ('\*',"")
            }

            New-Object -TypeName psobject -Property $DomDFSProps
        }

        # process msDFS-NamespaceAnchor next
        $DFSData = @(Get-DSObject -SearchRoot $DFSDN @DSParams -Filter 'objectClass=msDFS-NamespaceAnchor' -Properties  Name,distinguishedName,'msDFS-SchemaMajorVersion',whenCreated)

        Foreach ($DFSItem in $DFSData) {
            $DomDFSProps = @{
                name = $DFSItem.Name
                objectClass = 'msDFS-NamespaceAnchor'
                'msDFS-SchemaMajorVersion' = $DFSItem.'msDFS-SchemaMajorVersion'
                whenCreated = $DFSItem.whenCreated
            }
            $DFSItemMembers = @(Get-DSObject -SearchRoot $DFSItem.distinguishedName @DSParams -Filter 'objectClass=msDFS-Namespacev2' -IncludeAllProperties)

            $DFSItemMembers | ForEach-Object {
                $ItemMemberLinks = @(Get-DSObject -SearchRoot $_.distinguishedName @DSParams -Filter 'objectClass=msDFS-Linkv2' -IncludeAllProperties)
                $_ | Add-Member -MemberType:NoteProperty -Name 'DFSItemLinks' -Value $ItemMemberLinks
            }

            $DomDFSProps.ItemMembers = $DFSItemMembers

            New-Object -TypeName psobject -Property $DomDFSProps
        }
    }
}



function Get-DSDFSR {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSDFSR.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $DSParams = @{
        ComputerName = $ComputerName
        Credential = $Credential
    }
    $DFSGroupTopologyProps = @( 'Name', 'distinguishedName', 'msDFSR-ComputerReference')

    $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
    $DomNamingContext = $RootDSE.RootDomainNamingContext
    $DFSRDN = "CN=DFSR-GlobalSettings,CN=System,$DomNamingContext"

    if ((Test-DSObjectPath -Path $DFSRDN @DSParams)) {
        $DFSRGroups = @(Get-DSObject -SearchRoot $DFSRDN @DSParams -Filter 'objectClass=msDFSR-ReplicationGroup' -Properties 'Name','distinguishedName')
        Foreach ($DFSRGroup in $DFSRGroups) {
            $DFSRGC = @()
            $DFSRGTop = @()
            $DFSRGroupContentDN = "CN=Content,$($DFSRGroup.distinguishedName)"
            $DFSRGroupTopologyDN = "CN=Topology,$($DFSRGroup.distinguishedName)"

            $DFSRGroupContent = @(Get-DSObject -SearchRoot $DFSRGroupContentDN @DSParams -Filter 'objectClass=msDFSR-ContentSet' -Properties 'Name')
            $DFSRGC = @($DFSRGroupContent | ForEach-Object {$_.Name})

            $DFSRGroupTopology = @(Get-DSObject -SearchRoot $DFSRGroupTopologyDN @DSParams -Filter 'objectClass=msDFSR-Member' -Properties $DFSGroupTopologyProps)

            foreach ($DFSRGroupTopologyItem in $DFSRGroupTopology) {
                $DFSRServerName = Get-ADPathName $DFSRGroupTopologyItem.'msDFSR-ComputerReference' -GetElement 0 -ValuesOnly
                $DFSRGTop += [string]$DFSRServerName
            }
            $DomDFSRProps = @{
                Name = $DFSRGroup.Name
                Content = $DFSRGC
                RemoteServerName = $DFSRGTop
            }

            New-Object -TypeName psobject -Property $DomDFSRProps
        }
    }
}


function Get-DSDirectoryContext {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSDirectoryContext.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [ValidateSet('ApplicationPartition','ConfigurationSet','DirectoryServer','Domain','Forest')]
        [Alias('Type','Context')]
        [string]$ContextType = 'Domain',

        [Parameter()]
        [Alias('Name','Domain','Forest','DomainName','ForestName')]
        [string]$ContextName
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    Process {
       switch ($ContextType) {
            'Domain' {
                if ([string]::IsNullOrEmpty($ContextName)) {
                    if ($Script:CurrentDomain -ne $null) {
                        $ContextName = ($Script:CurrentDomain).Name
                    }
                    else {
                        $ContextName = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                    }
                }
                $ArgumentList = $ContextType,$ContextName
            }
            'Forest' {
                if ([string]::IsNullOrEmpty($ContextName)) {
                    if ($Script:CurrentForest -ne $null) {
                        $ContextName = ($Script:CurrentForest).Name
                    }
                    else {
                        $ContextName = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentforest()
                    }
                }
                $ArgumentList = $ContextType,$ContextName
            }
            'DirectoryServer' {
                if ([string]::IsNullOrEmpty($ContextName)) {
                    if ([string]::IsNullOrEmpty($Script:CurrentServer)) {
                        throw "$($FunctionName): No currently connected server and no context name was passed, cannot create a DirectoryContext as a DirectoryServer"
                    }
                    else {
                        $ContextName = $Script:CurrentServer
                    }
                }
                $ArgumentList = $ContextType,$ContextName
            }
            Default { $ArgumentList = $ContextType }
        }
        switch ( $ADConnectState ) {
            'AltUserAndServer' {
                $ArgumentList += "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password
            }
            'AltUser' {
                $ArgumentList += "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password
            }

        }

        New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList $ArgumentList
    }
}



function Get-DSDirectoryEntry {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSDirectoryEntry.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, HelpMessage = 'The distinguished name of the directory entry to retrieve.')]
        [Alias('DN')]
        [string]$DistinguishedName,

        [Parameter(HelpMessage = 'Domain controller to connect to for the query.')]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(HelpMessage = 'Credential to use for connection.')]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, HelpMessage = 'Query LDAP or Global Catalog (GC), default is LDAP')]
        [ValidateSet('LDAP', 'GC')]
        [string]$PathType = 'LDAP'
    )

    Begin {
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Managed DN includes path type. (performing case insensitive starts with check)
        if ($DistinguishedName.StartsWith('LDAP',$true,$null)) {
            $PathType = 'LDAP'
            $DistinguishedName = $DistinguishedName.Split('://')[3]
        }

        if ($DistinguishedName.StartsWith('GC',$true,$null)) {
            $PathType = 'GC'
            $DistinguishedName = $DistinguishedName.Split('://')[3]
        }

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    Process {
        switch ( $ADConnectState ) {
            'AltUserAndServer' {
                Write-Verbose "$($FunctionName): Alternate user and server."
                if ($DistinguishedName){
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)/$($DistinguishedName)"
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)"
                }
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath, "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password)
            }
            'AltUser' {
                Write-Verbose "$($FunctionName): Alternate user = $($SplitCreds.Domain)\$($SplitCreds.UserName)"
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    $fullpath = ''
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                }
                #$fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                Write-Verbose "$($FunctionName): Full path = $fullPath"
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath, "$($SplitCreds.Domain)\$($SplitCreds.UserName)", $SplitCreds.Password)
            }
            'CurrentUserAltServer' {
                Write-Verbose "$($FunctionName): Current user, alternate server."
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)"
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($ComputerName)/$($DistinguishedName)"
                }
                New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath)
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ([string]::IsNullOrEmpty($DistinguishedName)) {
                    New-Object -TypeName System.DirectoryServices.DirectoryEntry
                }
                else {
                    $fullPath = "$($PathType.ToUpper())://$($DistinguishedName)"
                    New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList @($fullPath)
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }
    }
}



function Get-DSDirectorySearcher {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSDirectorySearcher.md
    #>
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.DirectorySearcher])]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string]$Filter = 'distinguishedName=*',

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string[]]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName

        # Get the list of parameters for the command
        $PassedParams = @{}
        foreach($p in @((Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters).Values ) {
            if ($Script:CommonParameters -notcontains $p.Name) {
                $PassedParams.($p.Name) = (Get-Variable -Name $p.Name -ErrorAction SilentlyContinue).Value
            }
        }
        $Script:LastSearchSetting = new-object psobject -Property $PassedParams
    }

    process {
        switch ( $ADConnectState ) {
            { @('AltUserAndServer', 'CurrentUserAltServer', 'AltUser') -contains $_ } {
                Write-Verbose "$($FunctionName): Alternate user and/or server (State = $ADConnectState)"
                if ($searchRoot.Length -gt 0) {
                    Write-Verbose "$($FunctionName): searchRoot defined as $searchRoot"
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -DistinguishedName $searchRoot -Credential $Credential
                }
                else {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -Credential $Credential
                }
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ($searchRoot.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -DistinguishedName $searchRoot
                }
                else {
                    $domObj = Get-DSDirectoryEntry
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }

        $objSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList @($domObj, $Filter, $Properties) -Property @{
            PageSize = $PageSize
            SearchScope = $SearchScope
            Tombstone = $TombStone
            SecurityMasks = [System.DirectoryServices.SecurityMasks]$SecurityMask
            CacheResults = $false
        }

        if ($SizeLimit -ne 0) {
            Write-Verbose "$($FunctionName): Limiting search results to $Limit"
            $objSearcher.SizeLimit = $Limit
        }

        $objSearcher
    }
}



function Get-DSDomain {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSDomain.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name','Domain','DomainName')]
        [string]$Identity = ($Script:CurrentDomain).name,

        [Parameter( Position = 1 )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position = 2 )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter( Position = 3 )]
        [switch]$UpdateCurrent
    )

    Begin {
        # Function initialization
        if ($Script:IsLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    Process {
        try {
            $context = Get-DSDirectoryContext -ContextType 'Domain' -ContextName $DomainName -ComputerName $ComputerName -Credential $Credential
            $DomainObject = [DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)

            $RootDN = "DC=$(($DomainObject.Name).replace('.',',DC='))"
            $DEObj = Get-DSDirectoryEntry -DistinguishedName $RootDN -ComputerName $ComputerName -Credential $Credential
            $Sid = (New-Object -TypeName System.Security.Principal.SecurityIdentifier($DEObj.objectSid.value,0)).value
            $guid = "$([guid]($DEObj.objectguid.Value))"

            Add-Member -InputObject $DomainObject -MemberType NoteProperty -Name 'Sid' -Value $Sid
            Add-Member -InputObject $DomainObject -MemberType NoteProperty -Name 'Guid' -Value $guid

            if ($UpdateCurrent) {
                $Script:CurrentDomain = $DomainObject
            }
            else {
                $DomainObject
            }
        }
        catch {
            throw
        }
    }
}



function Get-DSExchangeFederation {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSExchangeFederation.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        $ExchangeConfig = @(Get-DSExchangeSchemaVersion @DSParams)
        if ($null -eq $ExchangeConfig) {
            # Exchange isn't in the environment
            Write-Verbose "$($FunctionName): No exchange environment found."
            return $null
        }
        $Props_ExchOrgs = @(
            'distinguishedName',
            'Name'
        )
        $Props_ExchFeds = @(
            'Name',
            'msExchFedIsEnabled',
            'msExchFedDomainNames',
            'msExchFedEnabledActions',
            'msExchFedTargetApplicationURI',
            'msExchFedTargetAutodiscoverEPR',
            'msExchVersion'
        )
        $ConfigNamingContext = (Get-DSConfigPartition @DSParams).distinguishedname
        $Path_ExchangeOrg = "LDAP://CN=Microsoft Exchange,CN=Services,$($ConfigNamingContext)"
        $ExchangeFederations = @()
    }

    end {
        if (Test-DSObjectPath -Path $Path_ExchangeOrg @DSParams) {
            $ExchOrgs = @(Get-DSObject -Filter 'objectClass=msExchOrganizationContainer' -SearchRoot $Path_ExchangeOrg -SearchScope:SubTree -Properties $Props_ExchOrgs @DSParams)

            ForEach ($ExchOrg in $ExchOrgs) {
                $ExchServers = @(Get-DSObject -Filter 'objectCategory=msExchExchangeServer' -SearchRoot $ExchOrg.distinguishedname -SearchScope:SubTree -Properties $Props_ExchServers  @DSParams)

                # Get all found Exchange federations
                $ExchangeFeds = @(Get-DSObject -Filter 'objectCategory=msExchFedSharingRelationship' -SearchRoot "LDAP://CN=Federation,$([string]$ExchOrg.distinguishedname)" -SearchScope:SubTree -Properties $Props_ExchFeds)
                Foreach ($ExchFed in $ExchangeFeds) {
                    New-Object -TypeName psobject -Property @{
                        Organization = $ExchOrg.Name
                        Name = $ExchFed.Name
                        Enabled = $ExchFed.msExchFedIsEnabled
                        Domains = @($ExchFed.msExchFedDomainNames)
                        AllowedActions = @($ExchFed.msExchFedEnabledActions)
                        TargetAppURI = $ExchFed.msExchFedTargetApplicationURI
                        TargetAutodiscoverEPR = $ExchFed.msExchFedTargetAutodiscoverEPR
                        ExchangeVersion = $ExchFed.msExchVersion
                    }
                }
            }
        }
        else {
            Write-Warning "$($FunctionName): Exchange found in schema but nothing found in services path - $Path_ExchangeOrg"
            return $null
        }
    }
}



function Get-DSExchangeSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSExchangeSchemaVersion.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    process {
        try {
            $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' -ComputerName $ComputerName -Credential $Credential
            $RangeUpper = (Get-DSObject -SearchRoot "CN=ms-Exch-Schema-Version-Pt,CN=Schema,$($rootDSE.configurationNamingContext)" -Properties 'rangeUpper' -ComputerName $ComputerName -Credential $Credential).rangeUpper

            if (($Script:SchemaVersionTable).Keys -contains $RangeUpper) {
                Write-Verbose "$($FunctionName): Exchange schema version found."
                $Script:SchemaVersionTable[$RangeUpper]
            }
            else {
                Write-Verbose "$($FunctionName): Exchange schema version not in our list."
                $RangeUpper
            }
        }
        catch {
            return $null
        }
    }
}



function Get-DSExchangeServer {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSExchangeServer.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        $ExchangeConfig = @(Get-DSExchangeSchemaVersion @DSParams)
        if ($ExchangeConfig -eq $null) {
            # Exchange isn't in the environment
            Write-Verbose "$($FunctionName): No exchange environment found."
            return $null
        }
        $Props_ExchOrgs = @(
            'distinguishedName',
            'Name'
        )
        $Props_ExchServers = @(
            'adspath',
            'Name',
            'msexchserversite',
            'msexchcurrentserverroles',
            'adminDisplayName',
            'whencreated',
            'serialnumber',
            'msexchproductid'
        )

        $ConfigNamingContext = (Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams).configurationNamingContext
        $Path_ExchangeOrg = "LDAP://CN=Microsoft Exchange,CN=Services,$($ConfigNamingContext)"
    }

    end {
        if (Test-DSObjectPath -Path $Path_ExchangeOrg @DSParams) {

            $ExchOrgs = @(Get-DSObject -Filter 'objectClass=msExchOrganizationContainer' -SearchRoot $Path_ExchangeOrg -SearchScope:SubTree -Properties $Props_ExchOrgs @DSParams)

            ForEach ($ExchOrg in $ExchOrgs) {
                $ExchServers = @(Get-DSObject -Filter 'objectCategory=msExchExchangeServer' -SearchRoot $ExchOrg.distinguishedname  -SearchScope:SubTree -Properties $Props_ExchServers  @DSParams)

                # Get all found Exchange server information
                ForEach ($ExchServer in $ExchServers) {
                    $AdminGroup = Get-ADPathName $ExchServer.adspath -GetElement 2 -ValuesOnly
                    $ExchSite =  Get-ADPathName $ExchServer.msexchserversite -GetElement 0 -ValuesOnly
                    $ExchRole = $ExchServer.msexchcurrentserverroles

                    # only have two roles in Exchange 2013 so we process a bit differently
                    if ($ExchServer.serialNumber -like "Version 15*") {
                        switch ($ExchRole) {
                            '54' {
                                $ExchRole = 'MAILBOX'
                            }
                            '16385' {
                                $ExchRole = 'CAS'
                            }
                            '16439' {
                                $ExchRole = 'MAILBOX, CAS'
                            }
                        }
                    }
                    else {
                        if($ExchRole -ne 0) {
                            $ExchRole = [Enum]::Parse('MSExchCurrentServerRolesFlags', $ExchRole)
                        }
                    }
                    $ServerVersion = $ExchServer.serialnumber
                    if ($ExchServer.serialnumber -match '^Version\s(.*)\s\(.*$') {
                        $ThisServerVersion = $Matches[1]
                        if ($ExchangeServerVersions.ContainsKey($ThisServerVersion)) {
                            $ServerVersion = $ExchangeServerVersions.($ThisServerVersion)
                        }
                    }
                    New-Object -TypeName PSObject -Property @{
                        Organization = $ExchOrg.Name
                        AdminGroup = $AdminGroup
                        Name = $ExchServer.adminDisplayName
                        Version = $ServerVersion
                        Role = $ExchRole
                        Site = $ExchSite
                        Created = $ExchServer.whencreated
                        Serial = $ExchServer.serialnumber
                        ProductID = $ExchServer.msexchproductid
                    }
                }
            }
        }
        else {
            Write-Warning "$($FunctionName): Exchange found in schema but nothing found in services path - $Path_ExchangeOrg"
            return $null
        }
    }
}


function Get-DSForest {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSForest.md
    #>
    [CmdletBinding()]
    param(
        [Parameter( Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True )]
        [Alias('Name','Forest','ForestName')]
        [string]$Identity = ($Script:CurrentForest).name,

        [Parameter( Position=1 )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter( Position=2 )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter()]
        [switch]$UpdateCurrent
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    Process {
        $context = Get-DSDirectoryContext -ContextType 'Forest' -ContextName $Identity -ComputerName $ComputerName -Credential $Credential
        $ForestObject = [DirectoryServices.ActiveDirectory.Forest]::GetForest($context)
        $RootDN = "DC=$(($ForestObject.Name).replace('.',',DC='))"
        $DEObj = Get-DSDirectoryEntry -DistinguishedName $RootDN -ComputerName $ComputerName -Credential $Credential
        $Sid = (New-Object -TypeName System.Security.Principal.SecurityIdentifier($DEObj.objectSid.value,0)).value
        Add-Member -InputObject $ForestObject -MemberType NoteProperty -Name 'Sid' -Value $Sid

        $ForestSid = (New-Object System.Security.Principal.NTAccount($ForestObject.RootDomain,"krbtgt")).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $Parts = $ForestSid -Split "-"
        $ForestSid = $Parts[0..$($Parts.length-2)] -join "-"
        $ForestObject | Add-Member NoteProperty 'RootDomainSid' $ForestSid

        if ($UpdateCurrent) {
            $Script:CurrentForest = $ForestObject
        }
        else {
            $ForestObject
        }
    }
}



function Get-DSForestTrust {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSForestTrust.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name','Forest','ForestName')]
        [string]$Identity = ($Script:CurrentForest).name,

        [Parameter(Position=1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position=2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    Process {
        Write-Verbose "$($FunctionName): Attempting to get forest trusts for $Identity."
        (Get-DSForest -Identity $Identity -ComputerName $ComputerName -Credential $Credential).GetAllTrustRelationships()
    }
}



function Get-DSFRS {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSFRS.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $DSParams = @{
        ComputerName = $ComputerName
        Credential = $Credential
    }
    $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
    $DomNamingContext = $RootDSE.RootDomainNamingContext
    $FRSDN = "CN=File Replication Service,CN=System,$DomNamingContext"

    $FRSReplicaSetProps = @( 'name', 'distinguishedName', 'fRSReplicaSetType', 'fRSFileFilter', 'whenCreated')
    $FRSReplicaSetItemProps = @( 'name', 'distinguishedName', 'frsComputerReference', 'whenCreated')

    if ((Test-DSObjectPath -Path $FRSDN @DSParams)) {

        $FRSReplicaSets = @(Get-DSObject -SearchRoot $FRSDN @DSParams -Filter 'objectClass=nTFRSReplicaSet' -Properties $FRSReplicaSetProps)

        Foreach ($FRSReplicaSet in $FRSReplicaSets) {
            $FRSProps = @{
               FRSReplicaSetName = $FRSReplicaSet.name
               FRSReplicaSetType = $FRSReplicaSet.fRSReplicaSetType
               FRSFileFilter = $FRSReplicaSet.fRSFileFilter
               FRSReplicaWhenCreated = $FRSReplicaSet.whenCreated
            }

            $FRSProps.ReplicaSetItems = @(Get-DSObject -SearchRoot $FRSReplicaSet.distinguishedName @DSParams -Filter 'objectClass=nTFRSMember' -Properties $FRSReplicaSetItemProps)

            New-Object -TypeName psobject -Property $FRSProps
        }
    }
}


function Get-DSGPO {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSGPO.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [string[]]$UserExtension,

        [Parameter()]
        [string[]]$MachineExtension
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build our base filter (overwrites any dynamic parameter sent base filter)
        $BaseFilters = @('objectCategory=groupPolicyContainer')

        # Filter on User Extension Filter.
        if ($UserExtension) {
            $LDAPFilters += "|(gpcuserextensionnames=*{0})" -f ($UserExtension -join '*)(gpcuserextensionnames=*')
        }

        # Filter on Machine Extension Filter.
        if ($MachineExtension) {
            $LDAPFilters += "|(gpcmachineextensionnames=*{0})" -f ($UserExtension -join '*)(gpcmachineextensionnames=*')
        }

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}


Function Get-DSGPOPassword {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSGPOPassword.md
    #>

    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [String]
        $Server = $Env:USERDNSDOMAIN
    )
    try {
        #ensure that machine is domain joined and script is running as a domain account
        if ( ( ((Get-WmiObject Win32_ComputerSystem).partofdomain) -eq $False ) -or ( -not $Env:USERDNSDOMAIN ) ) {
            throw 'Machine is not a domain member or User is not a member of the domain.'
        }

        #discover potential files containing passwords ; not complaining in case of denied access to a directory
        Write-Verbose "Searching \\$Server\SYSVOL. This could take a while."
        $XMlFiles = Get-ChildItem -Path "\\$Server\SYSVOL" -Recurse -ErrorAction SilentlyContinue -Include 'Groups.xml','Services.xml','Scheduledtasks.xml','DataSources.xml','Printers.xml','Drives.xml'

        if ( -not $XMlFiles ) {throw 'No preference files found.'}

        Write-Verbose "Found $($XMLFiles | Measure-Object | Select-Object -ExpandProperty Count) files that could contain passwords."

        foreach ($File in $XMLFiles) {
            $Result = (Get-GppInnerFields $File.Fullname)
            Write-Output $Result
        }
    }

    catch {
        Write-Error $Error[0]
    }
}


function Get-DSGroup {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSGroup.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [ValidateSet('Security','Distribution')]
        [string]$Category,

        [Parameter()]
        [switch]$AdminCount,

        [Parameter()]
        [switch]$Empty
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build our base filter (overwrites any dynamic parameter sent base filter)
        $BaseFilters = @('objectCategory=Group')

        # Filter by category
        if ($Category) {
            switch ($category) {
                'Distribution' {
                    $BaseFilters += '!(groupType:1.2.840.113556.1.4.803:=2147483648)'
                }
                'Security' {
                    $BaseFilters += 'groupType:1.2.840.113556.1.4.803:=2147483648'
                }
            }
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        if ($Empty) {
            $BaseFilters += "!(member=*)"
        }

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}



function Get-DSGroupMember {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSGroupMember.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [switch]$Recurse
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }

        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()
    }

    process {

        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        # Create a splat with only Get-DSObject parameters
        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }

        # Store another copy of the splat for later member lookup
        $GetMemberParams = $GetObjectParams.Clone()
        $GetMemberParams.Identity = $null

        $Identities += $Identity
    }

    end {
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for group: $ID"
            $GetObjectParams.Identity = $ID
            $GetObjectParams.Properties = 'distinguishedname'

            try {
                $GroupDN = (Get-DSGroup @GetObjectParams).distinguishedname
                if ($Recurse) {
                    $GetMemberParams.BaseFilter += "memberof:1.2.840.113556.1.4.1941:=$GroupDN"
                }
                else {
                    $GetMemberParams.BaseFilter += "memberof=$GroupDN"
                }

                Get-DSObject @GetMemberParams
            }
            catch {
                Write-Warning "$($FunctionName): Unable to find group with ID of $ID"
            }
        }
    }
}



function Get-DSGUIDMap {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSGUIDMap.md
    #>
    [CmdletBinding()]
    param ()

    begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
        return $Script:GUIDMap
    }
}



function Get-DSLastLDAPFilter {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSLastLDAPFilter.md
    #>
    [CmdletBinding()]
    param ()

    begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
        return ($Script:LastSearchSetting).Filter
    }
}



function Get-DSLastSearchSetting {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSLastSearchSetting.md
    #>
    [CmdletBinding()]
    param ()

    begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }
    process {
        return $Script:LastSearchSetting
    }
}



function Get-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSObject.md
    #>

    [CmdletBinding()]
    [OutputType([object],[System.DirectoryServices.DirectoryEntry],[System.DirectoryServices.DirectorySearcher])]
    param(
        [Parameter( position = 0 , ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, HelpMessage='Object to retreive.')]
        [Alias('sAMAccountName', 'distinguishedName')]
        [string]$Identity,

        [Parameter( position = 1, HelpMessage='Domain controller to use for this search.' )]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(HelpMessage='Credentials to connect with.' )]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(HelpMessage='Limit results. If zero there is no limit.')]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter(HelpMessage='Root path to search.')]
        [string]$SearchRoot,

        [Parameter(HelpMessage='LDAP filters to use.')]
        [string[]]$Filter,

        [Parameter(HelpMessage='Immutable base ldap filter to use.')]
        [string]$BaseFilter,

        [Parameter(HelpMessage='LDAP properties to return')]
        [string[]]$Properties = @('Name','distinguishedname'),

        [Parameter(HelpMessage='Page size for larger results.')]
        [int]$PageSize = $Script:PageSize,

        [Parameter(HelpMessage='Type of search.')]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter(HelpMessage='Security mask for search.')]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string[]]$SecurityMask = 'None',

        [Parameter(HelpMessage='Include tombstone objects.')]
        [switch]$TombStone,

        [Parameter(HelpMessage='Use logical OR instead of AND for custom LDAP filters.')]
        [switch]$ChangeLogicOrder,

        [Parameter(HelpMessage='Only include objects modified after this date.')]
        [datetime]$ModifiedAfter,

        [Parameter(HelpMessage='Only include objects modified before this date.')]
        [datetime]$ModifiedBefore,

        [Parameter(HelpMessage='Only include objects created after this date.')]
        [datetime]$CreatedAfter,

        [Parameter(HelpMessage='Only include objects created before this date.')]
        [datetime]$CreatedBefore,

        [Parameter(HelpMessage='Do not joine attribute values in output.')]
        [switch]$DontJoinAttributeValues,

        [Parameter(HelpMessage='Include all properties that have a value')]
        [switch]$IncludeAllProperties,

        [Parameter(HelpMessage='Include null property values')]
        [switch]$IncludeNullProperties,

        [Parameter(HelpMessage='Expand useraccountcontroll property (if it exists).')]
        [switch]$ExpandUAC,

        [Parameter(HelpMessage='Do no property transformations in output.')]
        [switch]$Raw,

        [Parameter(HelpMessage='How you want the results to be returned.')]
        [ValidateSet('psobject', 'directoryentry', 'searcher')]
        [string]$ResultsAs = 'psobject',

        [Parameter(HelpMessage='Escapes special characters in the filter ()/\*`0')]
        [switch]$LiteralFilter
    )

    Begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

    }
    Process {
        $SearcherParams = Get-CommonSearcherParams `
            -Identity $Identity `
            -ComputerName $ComputerName `
            -Credential $Credential `
            -Limit $Limit `
            -SearchRoot ($SearchRoot -replace 'LDAP://','') `
            -Filter $Filter `
            -BaseFilter $BaseFilter `
            -Properties $Properties `
            -PageSize $PageSize `
            -SearchScope $SearchScope `
            -SecurityMask $SecurityMask `
            -TombStone $TombStone `
            -ChangeLogicOrder $ChangeLogicOrder `
            -ModifiedAfter $ModifiedAfter `
            -ModifiedBefore $ModifiedBefore `
            -CreatedAfter $CreatedAfter `
            -CreatedBefore $CreatedBefore `
            -IncludeAllProperties $IncludeAllProperties `
            -IncludeNullProperties $IncludeNullProperties `
            -LiteralFilter $LiteralFilter

        # Store for later reference
        try {
            $objSearcher = Get-DSDirectorySearcher @SearcherParams
        }
        catch {
            throw $_
        }

        switch ($ResultsAs) {
            'directoryentry' {
                $objSearcher.findall() | Foreach {
                    $_.GetDirectoryEntry()
                }
            }
            'searcher' {
                $objSearcher.findall()
            }
            'psobject' {
                $objSearcher.findall() | ForEach-Object {
                    $ObjectProps = @{}
                    $_.Properties.GetEnumerator() | Foreach-Object {
                        $Val = @($_.Value)
                        $Prop = $_.Name
                        Write-Verbose "$($FunctionName): Property/Value set: $Prop = $Val"
                        if ($Prop -ne $null) {
                            if (-not $Raw) {
                                switch ($Prop) {
                                    'objectguid' {
                                        Write-Verbose "$($FunctionName): Reformatting objectguid"
                                        $Val = [guid]$Val[0]
                                    }
                                   <# 'msexchmailboxguid' {
                                        $Val = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::Unicode.GetBytes($Val[0]))
                                    } #>
                                { @( 'objectsid', 'sidhistory' ) -contains $_ } {
                                        Write-Verbose "$($FunctionName): Reformatting $Prop"
                                        $Val = New-Object System.Security.Principal.SecurityIdentifier $Val[0], 0
                                    }
                                    'lastlogontimestamp' {
                                        Write-Verbose "$($FunctionName): Reformatting lastlogontimestamp"
                                        $Val = [datetime]::FromFileTimeUtc($Val[0])
                                    }
                                    'ntsecuritydescriptor' {
                                        Write-Verbose "$($FunctionName): Reformatting ntsecuritydescriptor"
                                        $Val = (New-Object System.DirectoryServices.ActiveDirectorySecurity).SetSecurityDescriptorBinaryForm($Val[0])
                                    }
                                    'usercertificate' {
                                        Write-Verbose "$($FunctionName): Reformatting usercertificate"
                                        $Val = foreach ($cert in $Val) {[Security.Cryptography.X509Certificates.X509Certificate2]$cert}
                                    }
                                    'accountexpires' {
                                        Write-Verbose "$($FunctionName): Reformatting accountexpires"
                                        try {
                                            if (($Val[0] -eq 0) -or ($Val[0] -gt [DateTime]::MaxValue.Ticks)) {
                                                $Val = '<Never>'
                                            }
                                            else {
                                                $Val = ([DateTime]$exval).AddYears(1600).ToLocalTime()
                                            }
                                        }
                                        catch {
                                            $Val = '<Never>'
                                        }
                                    }
                                    { @('pwdlastset', 'lastlogon', 'badpasswordtime') -contains $_ } {
                                        Write-Verbose "$($FunctionName): Reformatting $Prop"
                                        $Val = [dateTime]::FromFileTime($Val[0])
                                    }
                                    'objectClass' {
                                        Write-Verbose "$($FunctionName): Storing objectClass in case we need it for later."
                                        $objClass = $Val | Select-Object -Last 1
                                    }
                                    'Useraccountcontrol' {
                                        if ($ExpandUAC) {
                                            Write-Verbose "$($FunctionName): Expanding $Prop = $Val"
                                            $Val = Convert-DSUACProperty -UACProperty ([string]($Val[0]))
                                        }
                                        else {
                                            Write-Verbose "$($FunctionName): Leaving $Prop in the default format."
                                        }
                                    }
                                    'grouptype' {
                                        Write-Verbose "$($FunctionName): Changing $Prop into additional properties, groupcategory and groupscope"
                                        switch ($Val[0]) {
                                            2 {
                                                $ObjectProps.Add('GroupCategory','Distribution')
                                                $ObjectProps.Add('GroupScope','Global')
                                            }
                                            4 {
                                                $ObjectProps.Add('GroupCategory','Distribution')
                                                $ObjectProps.Add('GroupScope','Local')
                                            }
                                            8 {
                                                $ObjectProps.Add('GroupCategory','Distribution')
                                                $ObjectProps.Add('GroupScope','Universal')
                                            }
                                            -2147483646 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Global')
                                            }
                                            -2147483644 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Local')
                                            }
                                            -2147483640 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Global')
                                            }
                                            -2147483643 {
                                                $ObjectProps.Add('GroupCategory','Security')
                                                $ObjectProps.Add('GroupScope','Builtin')
                                            }
                                            Default {
                                                $ObjectProps.Add('GroupCategory',$null)
                                                $ObjectProps.Add('GroupScope',$null)
                                            }
                                        }
                                    }
                                    { @('gpcmachineextensionnames','gpcuserextensionnames') -contains $_ } {
                                        Write-Verbose "$($FunctionName): Reformatting $Prop"
                                        $Val = Convert-DSCSE -CSEString $Val[0]
                                    }
                                    Default {
                                        # try to convert misc objects as best we can
                                        if ($Val[0] -is [System.Byte[]]) {
                                            try {
                                                Write-Verbose "$($FunctionName): Attempting reformatting of System.Byte[] - $Prop"
                                                $Val = Convert-ArrayToGUID $Val[0]
                                                [Int32]$High = $Temp.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $Val[0], $null)
                                                [Int32]$Low  = $Temp.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $Val[0], $null)
                                                $Val = [Int64]("0x{0:x8}{1:x8}" -f $High, $Low)
                                            }
                                            catch {
                                                Write-Verbose "$($FunctionName): Unable to  reformat System.Byte[] - $Prop"
                                            }
                                        }
                                    }
                                }
                            }
                            if ($DontJoinAttributeValues -and ($Val.Count -gt 1)) {
                                $ObjectProps.Add($Prop,$Val)
                            }
                            else {
                                $ObjectProps.Add($Prop,($Val -join ';'))
                            }
                        }
                    }

                    # Only return results that have more than 0 properties
                    if ($ObjectProps.psbase.keys.count -ge 1) {
                        # if we include all or even null properties then we poll the schema for our object's possible properties
                        if ($IncludeAllProperties -or $IncludeNullProperties) {
                            if (-not ($Script:__ad_schema_info.ContainsKey($ObjClass))) {
                                Write-Verbose "$($FunctionName): Storing schema attributes for $ObjClass for the first time"
                                Write-Verbose "$($FunctionName): Object class being queried for in the schema = $objClass"
                                ($Script:__ad_schema_info).$ObjClass = @(((Get-DSCurrentConnectedSchema).FindClass($objClass)).OptionalProperties).Name
                            }
                            else {
                                Write-Verbose "$($FunctionName): $ObjClass schema properties already loaded"
                            }

                            if ($IncludeAllProperties -and $IncludeNullProperties) {
                                ($Script:__ad_schema_info).$ObjClass | Foreach {
                                    if (-not ($ObjectProps.ContainsKey($_))) {
                                        # If the property exists in the schema but not in the searcher results
                                        # then it gets assigned a null value.
                                        $ObjectProps.$_ = $null
                                    }
                                }
                            }
                            elseif ($IncludeNullProperties) {
                                ($Script:__ad_schema_info).$ObjClass | Where {$Properties -contains $_}| Foreach {
                                    if (-not ($ObjectProps.ContainsKey($_))) {
                                        # If the property exists in the schema and our passed properties but not in
                                        # the searcher results then it gets assigned a null value.
                                        # This eliminates properties that may get passed by a user but that
                                        # don't exist on object.
                                        $ObjectProps.$_ = $null
                                    }
                                }
                            }
                        }
                        if (-not $IncludeAllProperties) {
                            # We only want to return properties that actually exist on the object
                            $Properties2 = $Properties | Where {$null -ne $_} | Where {$ObjectProps.ContainsKey($_)}
                        }
                        else {
                            # Or all the properties
                            $Properties2 = '*'
                        }
                        if ($null -ne $Properties2) {
                            New-Object PSObject -Property $ObjectProps | Select-Object $Properties2
                        }
                    }
                }
            }
        }
    }
    end {
        # Avoid memory leaks
        $objSearcher.dispose()
    }
}



function Get-DSObjectACL {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSObjectACL.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $ThisDomain = (Split-Credential -Credential $Credential).Domain
        $ThisForest = (Get-DSDomain -Identity $ThisDomain -Credential $Credential -ComputerName $ComputerName).Forest.Name
        Write-Verbose "Forest - $ThisForest"
        Get-GUIDMap -Forest $ThisForest -ComputerName $ComputerName -Credential $Credential

        $ACLOutput = @(
            @{'n'='DistingquishedName';'e'={$DN}},
            'ActiveDirectoryRights',
            'InheritanceType',
            @{'n'='ObjectType';'e'={$Script:GUIDMap[$ThisForest][$_.ObjectType.Guid]}},
            @{'n'='InheritedObjectType';'e'={$Script:GUIDMap[$ThisForest][$_.InheritedObjectType.Guid]}},
            'ObjectFlags',
            'AccessControlType',
            'IdentityReference',
            'IsInherited',
            'InheritanceFlags',
            'PropagationFlags'
        )
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }

        $Identities += $Identity
        $GetObjectParams.Properties = @('DistinguishedName')
        $GetObjectParams.ResultsAs = 'directoryentry'

        if ($null -eq $GetObjectParams.SecurityMask) {
            $GetObjectParams.SecurityMask = @('Dacl','Group','Owner')
            Write-Verbose "$($FunctionName): Since no security mask was set we will enable non-admin capable flags only (Dacl, Group, Owner)."
        }
    }
    end {
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | Foreach {
                $DN = $_.properties.distinguishedname[0]
                Write-Verbose "$($FunctionName): Found $DN"
                $_.PsBase.ObjectSecurity.Access | Select $ACLOutput
            }
        }
    }
}



function Get-DSOCSSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSOCSSchemaVersion.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $ConfigContext = $RootDSE.configurationNamingContext
    }

    end {
        # First get the schema version
        if ((Test-DSObjectPath -Path "CN=ms-RTC-SIP-SchemaVersion,$((Get-DSSchema).Name)" @DSParams)) {
            $RangeUpper = (Get-DSObject -SearchRoot "CN=ms-RTC-SIP-SchemaVersion,$((Get-DSSchema).Name)" -Properties 'rangeUpper' -ComputerName $ComputerName -Credential $Credential).rangeUpper

            if (($Script:SchemaVersionTable).Keys -contains $RangeUpper) {
                Write-Verbose "$($FunctionName): OCS/Skype/Lync schema version found."
                $OCSVersion = $Script:SchemaVersionTable[$RangeUpper]
            }
            else {
                Write-Verbose "$($FunctionName): OCS/Skype/Lync schema version not in our list!"
                $OCSVersion = $RangeUpper
            }

            # Config partition lookup, domain naming context
            $OCSDNPSearch = @(Get-DSObject -Filter 'objectclass=msRTCSIP-Service' -SearchRoot $DomNamingContext -SearchScope:SubTree @DSParams)
            if ($OCSDNPSearch.count -ge 1) {
                Write-Verbose "$($FunctionName): Configuration found installed to the system partition"
                New-Object -TypeName psobject -Property @{
                    Version = $OCSVersion
                    Partition = 'System'
                    ConfigPath = ($OCSDNPSearch[0]).adspath
                }
            }

            # Config partition lookup, configuration naming context
            $OCSCPSearch = @(Get-DSObject -Filter 'objectclass=msRTCSIP-Service' -SearchRoot $ConfigContext -SearchScope:SubTree @DSParams)
            if ($OCSCPSearch.count -ge 1) {
                Write-Verbose "$($FunctionName): Configuration found installed to the configuration partition"
                New-Object -TypeName psobject -Property @{
                    Version = $OCSVersion
                    Partition = 'Configuration'
                    ConfigPath = ($OCSCPSearch[0]).adspath
                }
            }
        }
        else {
            Write-Verbose "$($FunctionName): OCS/Skype/Lync not found in schema."
            New-Object -TypeName psobject -Property @{
                Version = 'Not Installed'
                Partition = $null
                ConfigPath = $null
            }
        }
    }
}



function Get-DSOCSTopology {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSOCSTopology.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        $OCSConfig = @(Get-DSOCSSchemaVersion @DSParams)
        if ($OCSConfig[0].ConfigPath -eq $null) {
            Write-Verbose "$($FunctionName): OCS/Lync/Skype not found in environment."
            return
        }
    }

    end {
        ForEach ($Config in $OCSConfig) {
            $Version = $Config.Version
            $Partition = $Config.Partition
            $ConfigPath = $Config.ConfigPath

            # All internal servers
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-TrustedServer' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-trustedserverfqdn','Name','cn','adspath' @DSParams) | Sort-Object msrtcsip-trustedserverfqdn | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Server'
                    Role = 'Internal'
                    Name = $_.Name
                    FQDN = $_.'msrtcsip-trustedserverfqdn'
                }
            }

            # All edge servers
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-EdgeProxy' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-edgeproxyfqdn','Name','cn' @DSParams) | Sort-Object msrtcsip-edgeproxyfqdn | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Server'
                    Role = 'Edge'
                    Name = $_.Name
                    FQDN = $_.'msrtcsip-edgeproxyfqdn'
                }
            }

                # All global topology servers
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-GlobalTopologySetting' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-backendserver','Name','cn','adspath' @DSParams) | Sort-Object msrtcsip-backendserver | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Server'
                    Role = 'Topology'
                    Name = $_.Name
                    FQDN = $_.'msrtcsip-backendserver'
                }
            }

            # All pools
            @(Get-DSObject -Filter 'objectClass=msRTCSIP-Pool' -SearchRoot $ConfigPath -SearchScope:SubTree -Properties 'msrtcsip-pooldisplayname','dnshostname','cn','adspath' @DSParams) | Sort-Object msrtcsip-pooldisplayname | ForEach-Object {
                New-Object -TypeName psobject -Property @{
                    Partition = $Partition
                    Path = $_.adspath
                    CN = $_.cn
                    Type = 'Pool'
                    Role = 'Pool'
                    Name = $_.'msrtcsip-pooldisplayname'
                    FQDN = $_.dnshostname
                }
            }
        }
    }
}



function Get-DSOptionalFeature {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSOptionalFeature.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $ConfigPathContext = "CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $ConfigPathContext @DSParams)) {
            Get-DSObject -SearchRoot $ConfigPathContext @DSParams -Filter 'objectClass=msDS-OptionalFeature' -Properties *
        }
        else {
            Write-Warning "$($FunctionName): Unable to find the path - $ConfigPathContext"
        }
    }
}



function Get-DSOrganizationalUnit {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSOrganizationalUnit.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build our base filter (overwrites any dynamic parameter sent base filter)
        $BaseFilters = @('objectCategory=organizationalUnit')

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}



function Get-DSPageSize {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSPageSize.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    return $Script:PageSize
}



function Get-DSRootDSE {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSRootDSE.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param()

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSDirectoryEntry' -CommandType 'Function'
    }
    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

    }
    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetDEParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSDirectoryEntryParameters -contains $_) } | Foreach-Object {
            $GetDEParams.$_ = $PSBoundParameters.$_
        }
        Write-Verbose "$($FunctionName): Directory Entry Search Parameters = $($GetDEParams)"
        $GetDEParams.DistinguishedName = 'rootDSE'

        try {
            Get-DSDirectoryEntry @GetDEParams
        }
        catch {
            throw $_
        }
    }
}



function Get-DSSCCMManagementPoint {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSSCCMManagementPoint.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $SysManageContext = "CN=System Management,CN=System,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $SysManageContext @DSParams)) {

            $SCCMData = @(Get-DSObject -SearchRoot $SysManageContext @DSParams -Filter 'objectClass=mSSMSManagementPoint' -Properties name,mSSMSCapabilities,mSSMSMPName,dNSHostName,mSSMSSiteCode,mSSMSVersion,mSSMSDefaultMP,mSSMSDeviceManagementPoint,whenCreated)

            Foreach ($SCCM in $SCCMData) {
                $SCCMxml = [XML]$SCCM.mSSMSCapabilities
                $schemaVersionSCCM = $SCCMxml.ClientOperationalSettings.Version
                if (($Script:SchemaVersionTable).Keys -contains $schemaVersionSCCM) {
                    Write-Verbose "$($FunctionName): SCCM version found."
                    $SCCMVer = $Script:SchemaVersionTable[$schemaVersionSCCM]
                }
                else {
                    Write-Verbose "$($FunctionName): SCCM version not in our list!"
                    $SCCMVer = $schemaVersionSCCM
                }
                New-Object -TypeName psobject -Property @{
                    name = $SCCM.name
                    Version = $SCCMVer
                    mSSMSMPName = $SCCM.mSSMSMPName
                    dNSHostName = $SCCM.dNSHostName
                    mSSMSSiteCode = $SCCM.mSSMSSiteCode
                    mSSMSVersion = $SCCM.mSSMSVersion
                    mSSMSDefaultMP = $SCCM.mSSMSDefaultMP
                    mSSMSDeviceManagementPoint = $SCCM.mSSMSDeviceManagementPoint
                    whenCreated = $SCCM.whenCreated
                }
            }
        }
    }
}



function Get-DSSCCMServiceLocatorPoint {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSSCCMServiceLocatorPoint.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $SysManageContext = "CN=System Management,CN=System,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $SysManageContext @DSParams)) {

            Get-DSObject -SearchRoot $SysManageContext @DSParams -Filter 'objectClass=mSSMSServerLocatorPoint' -Properties name,mSSMSMPName,mSSMSSiteCode,whenCreated
        }
    }
}



function Get-DSSchema {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSSchema.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('Name','Forest')]
        [string]$ForestName,

        [Parameter()]
        [switch]$UpdateCurrent
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
    }

    Process {
        try {
            $ForestContext = Get-DSDirectoryContext -ContextType 'Forest' -ContextName $ForestName -ComputerName $ComputerName -Credential $Credential
            $Schema = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]::GetSchema($ForestContext)

            if ($UpdateCurrent) {
                $Script:CurrentSchema = $Schema
            }
            else {
                $Schema
            }
        }
        catch {
            throw
        }
    }
}



function Get-DSSID {
<#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSSID.md
    #>
    [CmdletBinding(DefaultParameterSetName = 'Object')]
    param(
        [Parameter(Position = 0, Mandatory=$True, ValueFromPipeline=$True, ParameterSetName='Object')]
        [Alias('Group','User', 'Identity')]
        [String]$Name,

        [Parameter(Position = 0, Mandatory=$True, ValueFromPipeline=$True, ParameterSetName='SID')]
        [ValidatePattern('^S-1-.*')]
        [String]$SID,

        [Parameter(Position = 1)]
        [string]$Domain = ($Script:CurrentDomain).Name,

        [Parameter(Position = 2)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 3)]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    switch ($PsCmdlet.ParameterSetName) {
        'Object'  {
            $ObjectName = $Name -Replace "/","\"

            if($ObjectName.Contains("\")) {
                # if we get a DOMAIN\user format, auto convert it
                $Domain = $ObjectName.Split("\")[0]
                $ObjectName = $ObjectName.Split("\")[1]
            }
            elseif(-not $Domain) {
                Write-Verbose "$($FunctionName): No domain found in object name or passed to function, attempting to use currently connected domain name."
                try {
                    $Domain = (Get-DSCurrentConnectedDomain).Name
                }
                catch {
                    throw "$($FunctionName): Unable to retreive or find a domain name for object!"
                }
            }

            try {
                $Obj = (New-Object System.Security.Principal.NTAccount($Domain, $ObjectName))
                $Obj.Translate([System.Security.Principal.SecurityIdentifier]).Value
            }
            catch {
                Write-Warning "$($FunctionName): Invalid object/name - $Domain\$ObjectName"
            }
        }
        'SID' {
            ConvertTo-SecurityIdentifier -SID $SID
        }
    }

}


function Get-DSTombstoneLifetime {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSTombstoneLifetime.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
        $DSParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams
        $DomNamingContext = $RootDSE.RootDomainNamingContext
        $ConfigPathContext = "CN=Windows NT,CN=Services,CN=Configuration,$DomNamingContext"
    }

    end {
        if ((Test-DSObjectPath -Path $ConfigPathContext @DSParams)) {
            (Get-DSObject -SearchRoot $ConfigPathContext @DSParams -Filter 'objectClass=nTDSService' -Properties tombstoneLifetime).tombstoneLifetime
        }
        else {
            Write-Warning "$($FunctionName): Unable to find the path - $ConfigPathContext"
        }
    }
}



function Get-DSUser {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Get-DSUser.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [switch]$DotNotAllowDelegation,

        [Parameter()]
        [switch]$AllowDelegation,

        [Parameter()]
        [switch]$UnconstrainedDelegation,

        [Parameter()]
        [datetime]$LogOnAfter,

        [Parameter()]
        [datetime]$LogOnBefore,

        [Parameter()]
        [switch]$NoPasswordRequired,

        [Parameter()]
        [switch]$PasswordNeverExpires,

        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [switch]$Enabled,

        [Parameter()]
        [switch]$AdminCount,

        [Parameter()]
        [switch]$ServiceAccount,

        [Parameter()]
        [switch]$MustChangePassword,

        [Parameter()]
        [switch]$Locked
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }

        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Most efficient user ldap filter for user accounts: http://www.selfadsi.org/extended-ad/search-user-accounts.htm
        $BaseFilters = @('sAMAccountType=805306368')

        # Logon LDAP filter section
        $LogonLDAPFilters = @()
        if ($LogOnAfter) {
            $LogonLDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
        }
        if ($LogOnBefore) {
            $LogonLDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
        }
        $BaseFilters += Get-CombinedLDAPFilter -Filter $LogonLDAPFilters -Conditional '&'

        # Filter for accounts that are marked as sensitive and can not be delegated.
        if ($DotNotAllowDelegation) {
            $BaseFilters += 'userAccountControl:1.2.840.113556.1.4.803:=1048574'
        }

        if ($AllowDelegation) {
            # negation of "Accounts that are sensitive and not trusted for delegation"
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=1048574)"
        }

        # User has unconstrained delegation set.
        if ($UnconstrainedDelegation) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        # Account is locked
        if ($Locked) {
            $BaseFilters += 'lockoutTime>=1'
        }

        # Filter for accounts who do not requiere a password to logon.
        if ($NoPasswordRequired) {
            $BaseFilters += 'userAccountControl:1.2.840.113556.1.4.803:=32'
        }

        # Filter for accounts whose password does not expires.
        if ($PasswordNeverExpires) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=65536"
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $BaseFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $BaseFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $BaseFilters += "admincount>=1"
        }

        # Filter for accounts that have SPN set.
        if ($ServiceAccount) {
            $BaseFilters += "servicePrincipalName=*"
        }

        # Filter whose users must change their passwords.
        if ($MustChangePassword) {
            $BaseFilters += 'pwdLastSet=0'
        }

        $BaseFilter = Get-CombinedLDAPFilter -Filter $BaseFilters

        $Identities = @()
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams
        }
    }
}



function Move-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Move-DSObject.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [Alias('OU','TargetPath')]
        [string]$Destination,

        [Parameter(HelpMessage = 'Force move to OU without confirmation.')]
        [Switch]$Force
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()
        $YesToAll = $false
        $NoToAll = $false
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        # If the destination OU doesn't exist then there is nothing for us to do...
        if (-not (Test-DSObjectPath -Path $Destination @SearcherParams)) {
            throw "$($FunctionName): Destination OU doesn't seem to exist: $Destination"
        }
        else {
            # Otherwise get a DE of the destination OU for later
            Write-Verbose "$($FunctionName): Retreiving DN of the OU at $Destination"
            $OU = Get-DSDirectoryEntry @SearcherParams -DistinguishedName $Destination
        }

        $GetObjectParams.ResultsAs = 'DirectoryEntry'

        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | ForEach-Object {
                $Name = $_.Properties['name']
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Move AD Object $Name to $Destination", "Move AD Object $Name to $Destination?","Moving AD Object $Name")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to move '$Name'?", "Moving AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            $_.MoveTo($OU)
                        }
                        catch {
                            $ThisError = $_
                            Write-Error "$($FunctionName): Unable to move $Name - $ThisError"
                        }
                    }
                }
            }
        }
    }
}



function Remove-DSGroupMember {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Remove-DSGroupMember.md
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter()]
        [Alias('GroupName')]
        [string]$Group,

        [Parameter(HelpMessage = 'Force add group membership.')]
        [Switch]$Force
    )

    DynamicParam {
        # Create dictionary
        New-ProxyFunction -CommandName 'Get-DSObject' -CommandType 'Function'
    }

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()
        $YesToAll = $false
        $NoToAll = $false
    }

    process {
        # Pull in all the dynamic parameters (generated from get-dsobject)
        # as we might have values via pipeline we need to do this in the process block.
        if ($PSBoundParameters.Count -gt 0) {
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters
        }

        $GetObjectParams = @{}
        $PSBoundParameters.Keys | Where-Object { ($Script:GetDSObjectParameters -contains $_) } | Foreach-Object {
            $GetObjectParams.$_ = $PSBoundParameters.$_
        }
        $GetObjectParams.BaseFilter = $BaseFilter

        $Identities += $Identity
    }
    end {
        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'DirectoryEntry'
            Identity = $Group
        }

        try {
            # Otherwise get a DE of the group for later
            Write-Verbose "$($FunctionName): Retreiving directory entry of the group - $Group"
            $GroupDE = @(Get-DSGroup @SearcherParams)
        }
        catch {
            throw "Unable to get a directory entry for the specified group of $Group"
        }

        if ($GroupDE.Count -gt 1) {
            throw "More than one group result was found for $Group, exiting!"
        }
        else {
            $GroupDE = $GroupDE[0]
        }

        $GetObjectParams.Properties = 'adspath','name'

        Write-Verbose "$($FunctionName): Searching with base filter: $BaseFilter"
        Foreach ($ID in $Identities) {
            Write-Verbose "$($FunctionName): Searching for idenity: $($ID)"
            $GetObjectParams.Identity = $ID

            Get-DSObject @GetObjectParams | ForEach-Object {
                $Name = $_.name
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Remove $Name to $Group", "Remove $Name from $Group?","Removing $Name from $Group")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to remove '$Name'?", "Removing $Name from $Group", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            $GroupDE.Remove($_.adspath)
                        }
                        catch {
                            $ThisError = $_
                            Write-Warning "$($FunctionName): Unable to remove $Name to $Group"
                        }
                    }
                }
            }
        }
    }
}



function Set-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Set-DSObject.md
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium', DefaultParameterSetName = 'Default' )]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='Default')]
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='MultiProperty')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name','distinguishedname')]
        [string]$Identity,

        [Parameter(Position = 1, ParameterSetName='Default')]
        [Parameter(Position = 1, ParameterSetName='MultiProperty')]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2, ParameterSetName='Default')]
        [Parameter(Position = 2, ParameterSetName='MultiProperty')]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(Position = 3, ParameterSetName='MultiProperty')]
        [hashtable]$Properties,

        [Parameter(Position = 3, ParameterSetName='Default')]
        [string]$Property,

        [Parameter(Position = 4, ParameterSetName='Default')]
        [string]$Value,

        [Parameter(Position = 5, ParameterSetName='Default')]
        [Parameter(Position = 5, ParameterSetName='MultiProperty')]
        [Switch]$Force
    )

    begin {
        # Function initialization
        if ($Script:ThisModuleLoaded) {
            Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        }

        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $GenericProperties = @('name','adspath','distinguishedname')
        $Identities = @()
        $YesToAll = $false
        $NoToAll = $false

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
            ResultsAs = 'searcher'
        }

        switch ($PsCmdlet.ParameterSetName) {
            'Default'  {
                $SearcherParams.Properties = ($GenericProperties + $Property) | Select-Object -Unique
            }
            'MultiProperty' {
                $SearcherParams.Properties = ($GenericProperties + $Properties.Keys) | Select-Object -Unique
            }
        }
        Write-Verbose "$($FunctionName): Properties for this search include $($SearcherParams.Properties -join ', ')"
    }
    process {
        $SearcherParams.Identity = $Identity
        $Identities += Get-DSObject @SearcherParams
    }
    end {
        Foreach ($ID in $Identities) {
            $Name = $ID.Properties['name']
            $DE = $ID.GetDirectoryEntry()

            Write-Verbose "$($FunctionName): Start processing for object - $Name"
            switch ($PsCmdlet.ParameterSetName) {
                'Default'  {
                    Write-Verbose "$($FunctionName): Setting a single property"
                    if (($DE | Get-Member -MemberType 'Property').Name -contains $Property) {
                        $CurrentValue = $DE.$Property
                    }
                    else {
                        $CurrentValue = '<empty>'
                    }
                    Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                    if ($pscmdlet.ShouldProcess("Update AD Object $Name property = '$Property', value = '$Value' (Existing value is '$CurrentValue')", "Update AD Object $Name property = '$Property', value = '$Value' (Existing value is '$CurrentValue')","Updating AD Object $Name property $Property")) {
                        if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to Update '$Name' property $Property (Existing value is '$CurrentValue') with the value of $Value ?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                            try {
                                $DE.psbase.InvokeSet($Property,$Value)
                                $DE.SetInfo()
                            }
                            catch {
                                Write-Warning "$($FunctionName): Unable to update $Name property $Property with $Value"
                            }
                        }
                    }
                }
                'MultiProperty'  {
                    Write-Verbose "$($FunctionName): Setting multiple properties"
                    Foreach ($Prop in ($Properties.Keys)) {
                        try {
                            Write-Verbose "$($FunctionName): Setting $Prop to be $($Properties[$Prop])"
                            $DE.psbase.InvokeSet($Prop,$Properties[$Prop])
                        }
                        catch {
                            Write-Warning "$($FunctionName): Unable to update $Name property named: $Prop"
                        }
                    }
                    if ($pscmdlet.ShouldProcess("Update AD Object $Name", "Update AD Object $Name?","Updating AD Object $Name")) {
                        if ($Force -or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to Update '$Name'?", "Updating AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                            try {
                                $DE.SetInfo()
                            }
                            catch {
                                Write-Warning "$($FunctionName): Unable to update $Name"
                            }
                        }
                    }
                }
            }
        }
    }
}



function Set-DSPageSize {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Set-DSPageSize.md
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]$PageSize = 1000
    )

    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    $Script:PageSize = $PageSize
}



function Test-DSObjectPath {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.1.2/docs/Functions/Test-DSObjectPath.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]$Credential = $Script:CurrentCredential,

        [Parameter(Mandatory=$true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('adsPath')]
        [string]$Path
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
    }

    Process { }
    end {
        Write-Verbose "$($FunctionName): Validating the following path exists: $Path"

        switch ( $ADConnectState ) {
            { @('AltUserAndServer', 'CurrentUserAltServer', 'AltUser') -contains $_ } {
                Write-Verbose "$($FunctionName): Alternate user and/or server."
                if ($Path.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -DistinguishedName $Path -Credential $Credential

                }
                else {
                    $domObj = Get-DSDirectoryEntry -ComputerName $ComputerName -Credential $Credential
                }
            }
            'CurrentUser' {
                Write-Verbose "$($FunctionName): Current user."
                if ($Path.Length -gt 0) {
                    $domObj = Get-DSDirectoryEntry -DistinguishedName $Path
                }
                else {
                    $domObj = Get-DSDirectoryEntry
                }
            }
            Default {
                Write-Error "$($FunctionName): Unable to connect to AD!"
            }
        }

        if ($domObj.Path -eq $null) {
            return $false
        }
        else {
            return $true
        }
    }
}



## Post-Load Module code ##


# Use this variable for any path-sepecific actions (like loading dlls and such) to ensure it will work in testing and after being built
$MyModulePath = $(
    Function Get-ScriptPath {
        $Invocation = (Get-Variable MyInvocation -Scope 1).Value
        if($Invocation.PSScriptRoot) {
            $Invocation.PSScriptRoot
        }
        Elseif($Invocation.MyCommand.Path) {
            Split-Path $Invocation.MyCommand.Path
        }
        elseif ($Invocation.InvocationName.Length -eq 0) {
            (Get-Location).Path
        }
        else {
            $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
        }
    }

    Get-ScriptPath
)


$ExecutionContext.SessionState.Module.OnRemove = {
    # Action to take if the module is removed
}

$null = Register-EngineEvent -SourceIdentifier ( [System.Management.Automation.PsEngineEvent]::Exiting ) -Action {
    # Action to take if the whole pssession is killed
}

# Used in several functions to ignore parameters included with advanced functions
$CommonParameters = Get-CommonParameters

# Get a list of parameters for the get-dsobject command
$GetDSObjectParameters = Get-CommandParams -CommandName 'Get-DSObject' -CommandType 'Function'

# Get a list of parameters for the get-dsdirectoryentry command
$GetDSDirectoryEntryParameters = Get-CommandParams -CommandName 'Get-DSDirectoryEntry' -CommandType 'Function'

# Use this in your scripts to check if the function is being called from your module or independantly.
$ThisModuleLoaded = $true
<#
$Mod = New-InMemoryModule -ModuleName Win32

# all of the Win32 API functions we need
$FunctionDefinitions = @(
    (func netapi32 NetShareEnum ([Int]) @([String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetWkstaUserEnum ([Int]) @([String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetSessionEnum ([Int]) @([String], [String], [String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 NetLocalGroupGetMembers ([Int]) @([String], [String], [Int], [IntPtr].MakeByRefType(), [Int], [Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType())),
    (func netapi32 DsGetSiteName ([Int]) @([String], [IntPtr].MakeByRefType())),
    (func netapi32 DsEnumerateDomainTrusts ([Int]) @([String], [UInt32], [IntPtr].MakeByRefType(), [IntPtr].MakeByRefType())),
    (func netapi32 NetApiBufferFree ([Int]) @([IntPtr])),
    (func advapi32 ConvertSidToStringSid ([Int]) @([IntPtr], [String].MakeByRefType()) -SetLastError),
    (func advapi32 OpenSCManagerW ([IntPtr]) @([String], [String], [Int]) -SetLastError),
    (func advapi32 CloseServiceHandle ([Int]) @([IntPtr])),
    (func wtsapi32 WTSOpenServerEx ([IntPtr]) @([String])),
    (func wtsapi32 WTSEnumerateSessionsEx ([Int]) @([IntPtr], [Int32].MakeByRefType(), [Int], [IntPtr].MakeByRefType(), [Int32].MakeByRefType()) -SetLastError),
    (func wtsapi32 WTSQuerySessionInformation ([Int]) @([IntPtr], [Int], [Int], [IntPtr].MakeByRefType(), [Int32].MakeByRefType()) -SetLastError),
    (func wtsapi32 WTSFreeMemoryEx ([Int]) @([Int32], [IntPtr], [Int32])),
    (func wtsapi32 WTSFreeMemory ([Int]) @([IntPtr])),
    (func wtsapi32 WTSCloseServer ([Int]) @([IntPtr]))
)

# enum used by $WTS_SESSION_INFO_1 below
$WTSConnectState = psenum $Mod WTS_CONNECTSTATE_CLASS UInt16 @{
    Active = 0
    Connected = 1
    ConnectQuery = 2
    Shadow = 3
    Disconnected = 4
    Idle = 5
    Listen = 6
    Reset = 7
    Down = 8
    Init = 9
}

# the WTSEnumerateSessionsEx result structure
$WTS_SESSION_INFO_1 = struct $Mod WTS_SESSION_INFO_1 @{
    ExecEnvId = field 0 UInt32
    State = field 1 $WTSConnectState
    SessionId = field 2 UInt32
    pSessionName = field 3 String -MarshalAs @('LPWStr')
    pHostName = field 4 String -MarshalAs @('LPWStr')
    pUserName = field 5 String -MarshalAs @('LPWStr')
    pDomainName = field 6 String -MarshalAs @('LPWStr')
    pFarmName = field 7 String -MarshalAs @('LPWStr')
}

# the particular WTSQuerySessionInformation result structure
$WTS_CLIENT_ADDRESS = struct $mod WTS_CLIENT_ADDRESS @{
    AddressFamily = field 0 UInt32
    Address = field 1 Byte[] -MarshalAs @('ByValArray', 20)
}

# the NetShareEnum result structure
$SHARE_INFO_1 = struct $Mod SHARE_INFO_1 @{
    shi1_netname = field 0 String -MarshalAs @('LPWStr')
    shi1_type = field 1 UInt32
    shi1_remark = field 2 String -MarshalAs @('LPWStr')
}

# the NetWkstaUserEnum result structure
$WKSTA_USER_INFO_1 = struct $Mod WKSTA_USER_INFO_1 @{
    wkui1_username = field 0 String -MarshalAs @('LPWStr')
    wkui1_logon_domain = field 1 String -MarshalAs @('LPWStr')
    wkui1_oth_domains = field 2 String -MarshalAs @('LPWStr')
    wkui1_logon_server = field 3 String -MarshalAs @('LPWStr')
}

# the NetSessionEnum result structure
$SESSION_INFO_10 = struct $Mod SESSION_INFO_10 @{
    sesi10_cname = field 0 String -MarshalAs @('LPWStr')
    sesi10_username = field 1 String -MarshalAs @('LPWStr')
    sesi10_time = field 2 UInt32
    sesi10_idle_time = field 3 UInt32
}

# enum used by $LOCALGROUP_MEMBERS_INFO_2 below
$SID_NAME_USE = psenum $Mod SID_NAME_USE UInt16 @{
    SidTypeUser       =1
    SidTypeGroup      =2
    SidTypeDomain     =3
    SidTypeAlias      =4
    SidTypeWellKnownGroup   = 5
    SidTypeDeletedAccount   = 6
    SidTypeInvalid    =7
    SidTypeUnknown    =8
    SidTypeComputer   =9
}

# the NetLocalGroupGetMembers result structure
$LOCALGROUP_MEMBERS_INFO_2 = struct $Mod LOCALGROUP_MEMBERS_INFO_2 @{
    lgrmi2_sid = field 0 IntPtr
    lgrmi2_sidusage = field 1 $SID_NAME_USE
    lgrmi2_domainandname = field 2 String -MarshalAs @('LPWStr')
}

# enums used in DS_DOMAIN_TRUSTS
$DsDomainFlag = psenum $Mod DsDomain.Flags UInt32 @{
    IN_FOREST =1
    DIRECT_OUTBOUND = 2
    TREE_ROOT =4
    PRIMARY   =8
    NATIVE_MODE     = 16
    DIRECT_INBOUND  = 32
} -Bitfield

$DsDomainTrustType = psenum $Mod DsDomain.TrustType UInt32 @{
    DOWNLEVEL   = 1
    UPLEVEL     = 2
    MIT   =3
    DCE   =4
}

$DsDomainTrustAttributes = psenum $Mod DsDomain.TrustAttributes UInt32 @{
    NON_TRANSITIVE      = 1
    UPLEVEL_ONLY  =2
    FILTER_SIDS   =4
    FOREST_TRANSITIVE   = 8
    CROSS_ORGANIZATION  = 16
    WITHIN_FOREST =32
    TREAT_AS_EXTERNAL   = 64
}

# the DsEnumerateDomainTrusts result structure
$DS_DOMAIN_TRUSTS = struct $Mod DS_DOMAIN_TRUSTS @{
    NetbiosDomainName = field 0 String -MarshalAs @('LPWStr')
    DnsDomainName = field 1 String -MarshalAs @('LPWStr')
    Flags = field 2 $DsDomainFlag
    ParentIndex = field 3 UInt32
    TrustType = field 4 $DsDomainTrustType
    TrustAttributes = field 5 $DsDomainTrustAttributes
    DomainSid = field 6 IntPtr
    DomainGuid = field 7 Guid
}

$Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32'
$Netapi32 = $Types['netapi32']
$Advapi32 = $Types['advapi32']
$Wtsapi32 = $Types['wtsapi32']
#>




