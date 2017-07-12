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
}
else {
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

}

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

## PRIVATE MODULE FUNCTIONS AND DATA ##

function Add-Win32Type
{
<#
    .SYNOPSIS

        Creates a .NET type for an unmanaged Win32 function.

        Author: Matthew Graeber (@mattifestation)
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: func

    .DESCRIPTION

        Add-Win32Type enables you to easily interact with unmanaged (i.e.
        Win32 unmanaged) functions in PowerShell. After providing
        Add-Win32Type with a function signature, a .NET type is created
        using reflection (i.e. csc.exe is never called like with Add-Type).

        The 'func' helper function can be used to reduce typing when defining
        multiple function definitions.

    .PARAMETER DllName

        The name of the DLL.

    .PARAMETER FunctionName

        The name of the target function.

    .PARAMETER ReturnType

        The return type of the function.

    .PARAMETER ParameterTypes

        The function parameters.

    .PARAMETER NativeCallingConvention

        Specifies the native calling convention of the function. Defaults to
        stdcall.

    .PARAMETER Charset

        If you need to explicitly call an 'A' or 'W' Win32 function, you can
        specify the character set.

    .PARAMETER SetLastError

        Indicates whether the callee calls the SetLastError Win32 API
        function before returning from the attributed method.

    .PARAMETER Module

        The in-memory module that will host the functions. Use
        New-InMemoryModule to define an in-memory module.

    .PARAMETER Namespace

        An optional namespace to prepend to the type. Add-Win32Type defaults
        to a namespace consisting only of the name of the DLL.

    .EXAMPLE

        $Mod = New-InMemoryModule -ModuleName Win32

        $FunctionDefinitions = @(
          (func kernel32 GetProcAddress ([IntPtr]) @([IntPtr], [String]) -Charset Ansi -SetLastError),
          (func kernel32 GetModuleHandle ([Intptr]) @([String]) -SetLastError),
          (func ntdll RtlGetCurrentPeb ([IntPtr]) @())
        )

        $Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32'
        $Kernel32 = $Types['kernel32']
        $Ntdll = $Types['ntdll']
        $Ntdll::RtlGetCurrentPeb()
        $ntdllbase = $Kernel32::GetModuleHandle('ntdll')
        $Kernel32::GetProcAddress($ntdllbase, 'RtlGetCurrentPeb')

    .NOTES

        Inspired by Lee Holmes' Invoke-WindowsApi http://poshcode.org/2189

        When defining multiple function prototypes, it is ideal to provide
        Add-Win32Type with an array of function signatures. That way, they
        are all incorporated into the same in-memory module.
#>

    [OutputType([Hashtable])]
    Param(
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]
        $DllName,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [String]
        $FunctionName,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [Type]
        $ReturnType,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Type[]]
        $ParameterTypes,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Runtime.InteropServices.CallingConvention]
        $NativeCallingConvention = [Runtime.InteropServices.CallingConvention]::StdCall,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Runtime.InteropServices.CharSet]
        $Charset = [Runtime.InteropServices.CharSet]::Auto,

        [Parameter(ValueFromPipelineByPropertyName = $True)]
        [Switch]
        $SetLastError,

        [Parameter(Mandatory = $True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [ValidateNotNull()]
        [String]
        $Namespace = ''
    )

    BEGIN
    {
        $TypeHash = @{}
    }

    PROCESS
    {
        if ($Module -is [Reflection.Assembly])
        {
            if ($Namespace)
            {
                $TypeHash[$DllName] = $Module.GetType("$Namespace.$DllName")
            }
            else
            {
                $TypeHash[$DllName] = $Module.GetType($DllName)
            }
        }
        else
        {
            # Define one type for each DLL
            if (!$TypeHash.ContainsKey($DllName))
            {
                if ($Namespace)
                {
                    $TypeHash[$DllName] = $Module.DefineType("$Namespace.$DllName", 'Public,BeforeFieldInit')
                }
                else
                {
                    $TypeHash[$DllName] = $Module.DefineType($DllName, 'Public,BeforeFieldInit')
                }
            }

            $Method = $TypeHash[$DllName].DefineMethod(
                $FunctionName,
                'Public,Static,PinvokeImpl',
                $ReturnType,
                $ParameterTypes)

            # Make each ByRef parameter an Out parameter
            $i = 1
            ForEach($Parameter in $ParameterTypes)
            {
                if ($Parameter.IsByRef)
                {
                    [void] $Method.DefineParameter($i, 'Out', $Null)
                }

                $i++
            }

            $DllImport = [Runtime.InteropServices.DllImportAttribute]
            $SetLastErrorField = $DllImport.GetField('SetLastError')
            $CallingConventionField = $DllImport.GetField('CallingConvention')
            $CharsetField = $DllImport.GetField('CharSet')
            if ($SetLastError) { $SLEValue = $True } else { $SLEValue = $False }

            # Equivalent to C# version of [DllImport(DllName)]
            $Constructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([String])
            $DllImportAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($Constructor,
                $DllName, [Reflection.PropertyInfo[]] @(), [Object[]] @(),
                [Reflection.FieldInfo[]] @($SetLastErrorField, $CallingConventionField, $CharsetField),
                [Object[]] @($SLEValue, ([Runtime.InteropServices.CallingConvention] $NativeCallingConvention), ([Runtime.InteropServices.CharSet] $Charset)))

            $Method.SetCustomAttribute($DllImportAttribute)
        }
    }

    END
    {
        if ($Module -is [Reflection.Assembly])
        {
            return $TypeHash
        }

        $ReturnTypes = @{}

        ForEach ($Key in $TypeHash.Keys)
        {
            $Type = $TypeHash[$Key].CreateType()

            $ReturnTypes[$Key] = $Type
        }

        return $ReturnTypes
    }
}


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

    .DESCRIPTION
    `ConvertTo-SecurityIdentifier` converts a SID in SDDL form (as a string), in binary form (as a byte array) into a `System.Security.Principal.SecurityIdentifier` object. It also accepts `System.Security.Principal.SecurityIdentifier` objects, and returns them back to you.

    If the string or byte array don't represent a SID, an error is written and nothing is returned.

    .LINK
    Resolve-Identity

    .LINK
    Resolve-IdentityName

    .EXAMPLE
    Resolve-Identity -SID 'S-1-5-21-2678556459-1010642102-471947008-1017'

    Demonstrates how to convert a a SID in SDDL into a `System.Security.Principal.SecurityIdentifier` object.

    .EXAMPLE
    Resolve-Identity -SID (New-Object 'Security.Principal.SecurityIdentifier' 'S-1-5-21-2678556459-1010642102-471947008-1017')

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter. The SID you passed in will be returned to you unchanged.

    .EXAMPLE
    Resolve-Identity -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        # The SID to convert to a `System.Security.Principal.SecurityIdentifier`. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
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


function field
{
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [UInt16]
        $Position,

        [Parameter(Position = 1, Mandatory = $True)]
        [Type]
        $Type,

        [Parameter(Position = 2)]
        [UInt16]
        $Offset,

        [Object[]]
        $MarshalAs
    )

    @{
        Position = $Position
        Type = $Type -as [Type]
        Offset = $Offset
        MarshalAs = $MarshalAs
    }
}


function Find-UserField {
<#
    .SYNOPSIS

        Searches user object fields for a given word (default *pass*). Default
        field being searched is 'description'.

        Taken directly from @obscuresec's post:
            http://obscuresecurity.blogspot.com/2014/04/ADSISearcher.html

    .PARAMETER SearchTerm

        Term to search for, default of "pass".

    .PARAMETER SearchField

        User field to search, default of "description".

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER Domain

        Domain to search computer fields for, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .PARAMETER Credential

        A [Management.Automation.PSCredential] object of alternate credentials
        for connection to the target domain.

    .EXAMPLE

        PS C:\> Find-UserField -SearchField info -SearchTerm backup

        Find user accounts with "backup" in the "info" field.
#>

    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True)]
        [String]
        $SearchTerm = 'pass',

        [String]
        $SearchField = 'description',

        [String]
        $ADSpath,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [Management.Automation.PSCredential]
        $Credential
    )
 
    Get-NetUser -ADSpath $ADSpath -Domain $Domain -DomainController $DomainController -Credential $Credential -Filter "($SearchField=*$SearchTerm*)" -PageSize $PageSize | Select-Object samaccountname,$SearchField
}


function func
{
    Param
    (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $DllName,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $FunctionName,

        [Parameter(Position = 2, Mandatory = $True)]
        [Type]
        $ReturnType,

        [Parameter(Position = 3)]
        [Type[]]
        $ParameterTypes,

        [Parameter(Position = 4)]
        [Runtime.InteropServices.CallingConvention]
        $NativeCallingConvention,

        [Parameter(Position = 5)]
        [Runtime.InteropServices.CharSet]
        $Charset,

        [Switch]
        $SetLastError
    )

    $Properties = @{
        DllName = $DllName
        FunctionName = $FunctionName
        ReturnType = $ReturnType
    }

    if ($ParameterTypes) { $Properties['ParameterTypes'] = $ParameterTypes }
    if ($NativeCallingConvention) { $Properties['NativeCallingConvention'] = $NativeCallingConvention }
    if ($Charset) { $Properties['Charset'] = $Charset }
    if ($SetLastError) { $Properties['SetLastError'] = $SetLastError }

    New-Object PSObject -Property $Properties
}


function Get-ADIPAddress {
    [CmdletBinding()]
    [OutputType([string[]])]
    Param (
        # Computer name or FQDN to resolve
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        $ComputerName
    )

    Process {
        try {
            $IPArray = ([Net.Dns]::GetHostEntry($ComputerName)).AddressList
            foreach ($IPa in $IPArray) {
                $IPa.IPAddressToString
            }
        }
        catch {
            Write-Verbose -Message "Could not resolve $($computerName)"
        }
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

Function Get-CommonIDLDAPFilter {
	param (
		[String]$Identity,
		[String[]]$Filter
	)

	if ([string]::IsNullOrEmpty($Identity)) {
			# If no identity is passed then use a generic filter
			if ($Filter.Count -eq 0) {
				$Filter = @('name=*')
			}
	}
	else {
			# Otherwise use OR logic with some fuzzy matching
			$ObjID = Format-DSSearchFilterValue -SearchString $Identity
			Write-Verbose "$($FunctionName): Identity passed, any existing filters will be ignored."
			$Filter = @("distinguishedName=$ObjID","objectGUID=$ObjID","samaccountname=$ObjID")
	}

	@($Filter | Select-Object -Unique)
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


Function Get-DistinguishedNameFromFQDN {
    <#
    .SYNOPSIS
    TBD

    .DESCRIPTION
    TBD

    .PARAMETER fqdn
    fqdn explanation

	.NOTES
    Author: Zachary Loeber
    .LINK
    https://github.com/zloeber/PSAD
    #>

	param (
		[String]$fqdn = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
	)

	# Create a New Array 'Item' for each item in between the '.' characters
	# Arrayitem1 division
	# Arrayitem2 domain
	# Arrayitem3 root
	$FQDNArray = $FQDN.split(".")

	# Add A Separator of ','
	$Separator = ","

	# For Each Item in the Array
	# for (CreateVar; Condition; RepeatAction)
	# for ($x is now equal to 0; while $x is less than total array length; add 1 to X
	for ($x = 0; $x -lt $FQDNArray.Length ; $x++)
		{

		#If it's the last item in the array don't append a ','
		if ($x -eq ($FQDNArray.Length - 1)) { $Separator = "" }

		# Append to $DN DC= plus the array item with a separator after
		[string]$DN += "DC=" + $FQDNArray[$x] + $Separator

		# continue to next item in the array
		}

	#return the Distinguished Name
	return $DN

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


function Get-GptTmpl {
<#
    .SYNOPSIS

        Helper to parse a GptTmpl.inf policy file path into a custom object.

    .PARAMETER GptTmplPath

        The GptTmpl.inf file path name to parse. 

    .PARAMETER UsePSDrive

        Switch. Mount the target GptTmpl folder path as a temporary PSDrive.

    .EXAMPLE

        PS C:\> Get-GptTmpl -GptTmplPath "\\dev.testlab.local\sysvol\dev.testlab.local\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

        Parse the default domain policy .inf for dev.testlab.local
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $GptTmplPath,

        [Switch]
        $UsePSDrive
    )

    if($UsePSDrive) {
        # if we're PSDrives, create a temporary mount point
        $Parts = $GptTmplPath.split('\')
        $FolderPath = $Parts[0..($Parts.length-2)] -join '\'
        $FilePath = $Parts[-1]
        $RandDrive = ("abcdefghijklmnopqrstuvwxyz".ToCharArray() | Get-Random -Count 7) -join ''

        Write-Verbose "Mounting path $GptTmplPath using a temp PSDrive at $RandDrive"

        try {
            $Null = New-PSDrive -Name $RandDrive -PSProvider FileSystem -Root $FolderPath  -ErrorAction Stop
        }
        catch {
            Write-Verbose "Error mounting path $GptTmplPath : $_"
            return $Null
        }

        # so we can cd/dir the new drive
        $TargetGptTmplPath = $RandDrive + ":\" + $FilePath
    }
    else {
        $TargetGptTmplPath = $GptTmplPath
    }

    Write-Verbose "GptTmplPath: $GptTmplPath"

    try {
        Write-Verbose "Parsing $TargetGptTmplPath"
        $TargetGptTmplPath | Get-IniContent -ErrorAction SilentlyContinue
    }
    catch {
        Write-Verbose "Error parsing $TargetGptTmplPath : $_"
    }

    if($UsePSDrive -and $RandDrive) {
        Write-Verbose "Removing temp PSDrive $RandDrive"
        Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
    }
}


function Get-GroupsXML {
<#
    .SYNOPSIS

        Helper to parse a groups.xml file path into a custom object.

    .PARAMETER GroupsXMLpath

        The groups.xml file path name to parse. 

    .PARAMETER UsePSDrive

        Switch. Mount the target groups.xml folder path as a temporary PSDrive.
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [String]
        $GroupsXMLPath,

        [Switch]
        $UsePSDrive
    )

    if($UsePSDrive) {
        # if we're PSDrives, create a temporary mount point
        $Parts = $GroupsXMLPath.split('\')
        $FolderPath = $Parts[0..($Parts.length-2)] -join '\'
        $FilePath = $Parts[-1]
        $RandDrive = ("abcdefghijklmnopqrstuvwxyz".ToCharArray() | Get-Random -Count 7) -join ''

        Write-Verbose "Mounting path $GroupsXMLPath using a temp PSDrive at $RandDrive"

        try {
            $Null = New-PSDrive -Name $RandDrive -PSProvider FileSystem -Root $FolderPath  -ErrorAction Stop
        }
        catch {
            Write-Verbose "Error mounting path $GroupsXMLPath : $_"
            return $Null
        }

        # so we can cd/dir the new drive
        $TargetGroupsXMLPath = $RandDrive + ":\" + $FilePath
    }
    else {
        $TargetGroupsXMLPath = $GroupsXMLPath
    }

    try {
        [XML]$GroupsXMLcontent = Get-Content $TargetGroupsXMLPath -ErrorAction Stop

        # process all group properties in the XML
        $GroupsXMLcontent | Select-Xml "/Groups/Group" | Select-Object -ExpandProperty node | ForEach-Object {

            $Groupname = $_.Properties.groupName

            # extract the localgroup sid for memberof
            $GroupSID = $_.Properties.groupSid
            if(-not $GroupSID) {
                if($Groupname -match 'Administrators') {
                    $GroupSID = 'S-1-5-32-544'
                }
                elseif($Groupname -match 'Remote Desktop') {
                    $GroupSID = 'S-1-5-32-555'
                }
                elseif($Groupname -match 'Guests') {
                    $GroupSID = 'S-1-5-32-546'
                }
                else {
                    $GroupSID = Convert-NameToSid -ObjectName $Groupname | Select-Object -ExpandProperty SID
                }
            }

            # extract out members added to this group
            $Members = $_.Properties.members | Select-Object -ExpandProperty Member | Where-Object { $_.action -match 'ADD' } | ForEach-Object {
                if($_.sid) { $_.sid }
                else { $_.name }
            }

            if ($Members) {

                # extract out any/all filters...I hate you GPP
                if($_.filters) {
                    $Filters = $_.filters.GetEnumerator() | ForEach-Object {
                        New-Object -TypeName PSObject -Property @{'Type' = $_.LocalName;'Value' = $_.name}
                    }
                }
                else {
                    $Filters = $Null
                }

                if($Members -isnot [System.Array]) { $Members = @($Members) }

                $GPOGroup = New-Object PSObject
                $GPOGroup | Add-Member Noteproperty 'GPOPath' $TargetGroupsXMLPath
                $GPOGroup | Add-Member Noteproperty 'Filters' $Filters
                $GPOGroup | Add-Member Noteproperty 'GroupName' $GroupName
                $GPOGroup | Add-Member Noteproperty 'GroupSID' $GroupSID
                $GPOGroup | Add-Member Noteproperty 'GroupMemberOf' $Null
                $GPOGroup | Add-Member Noteproperty 'GroupMembers' $Members
                $GPOGroup
            }
        }
    }
    catch {
        Write-Verbose "Error parsing $TargetGroupsXMLPath : $_"
    }

    if($UsePSDrive -and $RandDrive) {
        Write-Verbose "Removing temp PSDrive $RandDrive"
        Get-PSDrive -Name $RandDrive -ErrorAction SilentlyContinue | Remove-PSDrive -Force
    }
}


filter Get-IniContent {
<#
.SYNOPSIS
This helper parses an .ini file into a proper PowerShell object.

.DESCRIPTION
This helper parses an .ini file into a proper PowerShell object.

.NOTES
Author: 'The Scripting Guys'

.LINK
https://blogs.technet.microsoft.com/heyscriptingguy/2011/08/20/use-powershell-to-work-with-any-ini-file/
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [ValidateScript({ Test-Path -Path $_ })]
        [String[]]
        $Path
    )

    ForEach($TargetPath in $Path) {
        $IniObject = @{}
        Switch -Regex -File $TargetPath {
            "^\[(.+)\]" # Section
            {
                $Section = $matches[1].Trim()
                $IniObject[$Section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" # Comment
            {
                $Value = $matches[1].Trim()
                $CommentCount = $CommentCount + 1
                $Name = 'Comment' + $CommentCount
                $IniObject[$Section][$Name] = $Value
            } 
            "(.+?)\s*=(.*)" # Key
            {
                $Name, $Value = $matches[1..2]
                $Name = $Name.Trim()
                $Values = $Value.split(',') | ForEach-Object {$_.Trim()}
                if($Values -isnot [System.Array]) {$Values = @($Values)}
                $IniObject[$Section][$Name] = $Values
            }
        }
        $IniObject
    }
}


filter Get-IPAddress {
<#
    .SYNOPSIS

        Resolves a given hostename to its associated IPv4 address. 
        If no hostname is provided, it defaults to returning
        the IP address of the localhost.

    .EXAMPLE

        PS C:\> Get-IPAddress -ComputerName SERVER
        
        Return the IPv4 address of 'SERVER'

    .EXAMPLE

        PS C:\> Get-Content .\hostnames.txt | Get-IPAddress

        Get the IP addresses of all hostnames in an input file.
#>

    [CmdletBinding()]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String]
        $ComputerName = $Env:ComputerName
    )

    try {
        # extract the computer name from whatever object was passed on the pipeline
        $Computer = $ComputerName | Get-NameField

        # get the IP resolution of this specified hostname
        @(([Net.Dns]::GetHostEntry($Computer)).AddressList) | ForEach-Object {
            if ($_.AddressFamily -eq 'InterNetwork') {
                $Out = New-Object PSObject
                $Out | Add-Member Noteproperty 'ComputerName' $Computer
                $Out | Add-Member Noteproperty 'IPAddress' $_.IPAddressToString
                $Out
            }
        }
    }
    catch {
        Write-Verbose -Message 'Could not resolve host to an IP Address.'
    }
}


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


function Get-PIIPAddress {
    # Retreive IP address informaton from dot net core only functions (should run on both linux and windows properly)
    $NetworkInterfaces = @([System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {($_.OperationalStatus -eq 'Up')})
    $NetworkInterfaces | Foreach-Object {
        $_.GetIPProperties() | Where-Object {$_.GatewayAddresses} | Foreach-Object {
            $Gateway = $_.GatewayAddresses.Address.IPAddressToString
            $DNSAddresses = @($_.DnsAddresses | Foreach-Object {$_.IPAddressToString})
            $_.UnicastAddresses | Where-Object {$_.Address -notlike '*::*'} | Foreach-Object {
                New-Object PSObject -Property @{
                    IP = $_.Address
                    Prefix = $_.PrefixLength
                    Gateway = $Gateway
                    DNS = $DNSAddresses
                }
            }
        }
    }
}


filter Get-Proxy {
<#
    .SYNOPSIS
    
        Enumerates the proxy server and WPAD conents for the current user.

    .PARAMETER ComputerName

        The computername to enumerate proxy settings on, defaults to local host.

    .EXAMPLE

        PS C:\> Get-Proxy 
        
        Returns the current proxy settings.
#>
    param(
        [Parameter(ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName = $ENV:COMPUTERNAME
    )

    try {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('CurrentUser', $ComputerName)
        $RegKey = $Reg.OpenSubkey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings")
        $ProxyServer = $RegKey.GetValue('ProxyServer')
        $AutoConfigURL = $RegKey.GetValue('AutoConfigURL')

        $Wpad = ""
        if($AutoConfigURL -and ($AutoConfigURL -ne "")) {
            try {
                $Wpad = (New-Object Net.Webclient).DownloadString($AutoConfigURL)
            }
            catch {
                Write-Warning "Error connecting to AutoConfigURL : $AutoConfigURL"
            }
        }
        
        if($ProxyServer -or $AutoConfigUrl) {

            $Properties = @{
                'ProxyServer' = $ProxyServer
                'AutoConfigURL' = $AutoConfigURL
                'Wpad' = $Wpad
            }
            
            New-Object -TypeName PSObject -Property $Properties
        }
        else {
            Write-Warning "No proxy settings found for $ComputerName"
        }
    }
    catch {
        Write-Warning "Error enumerating proxy settings for $ComputerName : $_"
    }
}


function Invoke-ThreadedFunction {
    # Helper used by any threaded host enumeration functions
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$True)]
        [String[]]
        $ComputerName,

        [Parameter(Position=1,Mandatory=$True)]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        [Parameter(Position=2)]
        [Hashtable]
        $ScriptParameters,

        [Int]
        [ValidateRange(1,100)] 
        $Threads = 20,

        [Switch]
        $NoImports
    )

    begin {

        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        Write-Verbose "[*] Total number of hosts: $($ComputerName.count)"

        # Adapted from:
        #   http://powershell.org/wp/forums/topic/invpke-parallel-need-help-to-clone-the-current-runspace/
        $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $SessionState.ApartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()

        # import the current session state's variables and functions so the chained PowerView
        #   functionality can be used by the threaded blocks
        if(!$NoImports) {

            # grab all the current variables for this runspace
            $MyVars = Get-Variable -Scope 2

            # these Variables are added by Runspace.Open() Method and produce Stop errors if you add them twice
            $VorbiddenVars = @("?","args","ConsoleFileName","Error","ExecutionContext","false","HOME","Host","input","InputObject","MaximumAliasCount","MaximumDriveCount","MaximumErrorCount","MaximumFunctionCount","MaximumHistoryCount","MaximumVariableCount","MyInvocation","null","PID","PSBoundParameters","PSCommandPath","PSCulture","PSDefaultParameterValues","PSHOME","PSScriptRoot","PSUICulture","PSVersionTable","PWD","ShellId","SynchronizedHash","true")

            # Add Variables from Parent Scope (current runspace) into the InitialSessionState
            ForEach($Var in $MyVars) {
                if($VorbiddenVars -NotContains $Var.Name) {
                $SessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Var.name,$Var.Value,$Var.description,$Var.options,$Var.attributes))
                }
            }

            # Add Functions from current runspace to the InitialSessionState
            ForEach($Function in (Get-ChildItem Function:)) {
                $SessionState.Commands.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $Function.Name, $Function.Definition))
            }
        }

        # threading adapted from
        # https://github.com/darkoperator/Posh-SecMod/blob/master/Discovery/Discovery.psm1#L407
        #   Thanks Carlos!

        # create a pool of maxThread runspaces
        $Pool = [runspacefactory]::CreateRunspacePool(1, $Threads, $SessionState, $Host)
        $Pool.Open()

        $method = $null
        ForEach ($m in [PowerShell].GetMethods() | Where-Object { $_.Name -eq "BeginInvoke" }) {
            $methodParameters = $m.GetParameters()
            if (($methodParameters.Count -eq 2) -and $methodParameters[0].Name -eq "input" -and $methodParameters[1].Name -eq "output") {
                $method = $m.MakeGenericMethod([Object], [Object])
                break
            }
        }

        $Jobs = @()
    }

    process {

        ForEach ($Computer in $ComputerName) {

            # make sure we get a server name
            if ($Computer -ne '') {
                # Write-Verbose "[*] Enumerating server $Computer ($($Counter+1) of $($ComputerName.count))"

                While ($($Pool.GetAvailableRunspaces()) -le 0) {
                    Start-Sleep -MilliSeconds 500
                }

                # create a "powershell pipeline runner"
                $p = [powershell]::create()

                $p.runspacepool = $Pool

                # add the script block + arguments
                $Null = $p.AddScript($ScriptBlock).AddParameter('ComputerName', $Computer)
                if($ScriptParameters) {
                    ForEach ($Param in $ScriptParameters.GetEnumerator()) {
                        $Null = $p.AddParameter($Param.Name, $Param.Value)
                    }
                }

                $o = New-Object Management.Automation.PSDataCollection[Object]

                $Jobs += @{
                    PS = $p
                    Output = $o
                    Result = $method.Invoke($p, @($null, [Management.Automation.PSDataCollection[Object]]$o))
                }
            }
        }
    }

    end {
        Write-Verbose "Waiting for threads to finish..."

        Do {
            ForEach ($Job in $Jobs) {
                $Job.Output.ReadAll()
            }
        } While (($Jobs | Where-Object { ! $_.Result.IsCompleted }).Count -gt 0)

        ForEach ($Job in $Jobs) {
            $Job.PS.Dispose()
        }

        $Pool.Dispose()
        Write-Verbose "All threads completed!"
    }
}


function New-InMemoryModule
{
<#
    .SYNOPSIS

        Creates an in-memory assembly and module

        Author: Matthew Graeber (@mattifestation)
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: None

    .DESCRIPTION

        When defining custom enums, structs, and unmanaged functions, it is
        necessary to associate to an assembly module. This helper function
        creates an in-memory module that can be passed to the 'enum',
        'struct', and Add-Win32Type functions.

    .PARAMETER ModuleName

        Specifies the desired name for the in-memory assembly and module. If
        ModuleName is not provided, it will default to a GUID.

    .EXAMPLE

        $Module = New-InMemoryModule -ModuleName Win32
#>

    Param
    (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ModuleName = [Guid]::NewGuid().ToString()
    )

    $LoadedAssemblies = [AppDomain]::CurrentDomain.GetAssemblies()

    ForEach ($Assembly in $LoadedAssemblies) {
        if ($Assembly.FullName -and ($Assembly.FullName.Split(',')[0] -eq $ModuleName)) {
            return $Assembly
        }
    }

    $DynAssembly = New-Object Reflection.AssemblyName($ModuleName)
    $Domain = [AppDomain]::CurrentDomain
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, 'Run')
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule($ModuleName, $False)

    return $ModuleBuilder
}


function psenum
{
<#
    .SYNOPSIS

        Creates an in-memory enumeration for use in your PowerShell session.

        Author: Matthew Graeber (@mattifestation)
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: None
     
    .DESCRIPTION

        The 'psenum' function facilitates the creation of enums entirely in
        memory using as close to a "C style" as PowerShell will allow.

    .PARAMETER Module

        The in-memory module that will host the enum. Use
        New-InMemoryModule to define an in-memory module.

    .PARAMETER FullName

        The fully-qualified name of the enum.

    .PARAMETER Type

        The type of each enum element.

    .PARAMETER EnumElements

        A hashtable of enum elements.

    .PARAMETER Bitfield

        Specifies that the enum should be treated as a bitfield.

    .EXAMPLE

        $Mod = New-InMemoryModule -ModuleName Win32

        $ImageSubsystem = psenum $Mod PE.IMAGE_SUBSYSTEM UInt16 @{
            UNKNOWN =                  0
            NATIVE =                   1 # Image doesn't require a subsystem.
            WINDOWS_GUI =              2 # Image runs in the Windows GUI subsystem.
            WINDOWS_CUI =              3 # Image runs in the Windows character subsystem.
            OS2_CUI =                  5 # Image runs in the OS/2 character subsystem.
            POSIX_CUI =                7 # Image runs in the Posix character subsystem.
            NATIVE_WINDOWS =           8 # Image is a native Win9x driver.
            WINDOWS_CE_GUI =           9 # Image runs in the Windows CE subsystem.
            EFI_APPLICATION =          10
            EFI_BOOT_SERVICE_DRIVER =  11
            EFI_RUNTIME_DRIVER =       12
            EFI_ROM =                  13
            XBOX =                     14
            WINDOWS_BOOT_APPLICATION = 16
        }

    .NOTES

        PowerShell purists may disagree with the naming of this function but
        again, this was developed in such a way so as to emulate a "C style"
        definition as closely as possible. Sorry, I'm not going to name it
        New-Enum. :P
#>

    [OutputType([Type])]
    Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FullName,

        [Parameter(Position = 2, Mandatory = $True)]
        [Type]
        $Type,

        [Parameter(Position = 3, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $EnumElements,

        [Switch]
        $Bitfield
    )

    if ($Module -is [Reflection.Assembly])
    {
        return ($Module.GetType($FullName))
    }

    $EnumType = $Type -as [Type]

    $EnumBuilder = $Module.DefineEnum($FullName, 'Public', $EnumType)

    if ($Bitfield)
    {
        $FlagsConstructor = [FlagsAttribute].GetConstructor(@())
        $FlagsCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($FlagsConstructor, @())
        $EnumBuilder.SetCustomAttribute($FlagsCustomAttribute)
    }

    ForEach ($Key in $EnumElements.Keys)
    {
        # Apply the specified enum type to each element
        $Null = $EnumBuilder.DefineLiteral($Key, $EnumElements[$Key] -as $EnumType)
    }

    $EnumBuilder.CreateType()
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
    PS C:\> Get-Credential $null
    Returns the current user settings. Password will be returned as $null.

    .NOTES
    Author: Zachary Loeber

    .LINK
    https://www.the-little-things.net
    #>
    [CmdletBinding()]
    param (
        [parameter()]
        [alias('Creds')]
        [System.Management.Automation.PSCredential]$Credential
    )
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


function struct
{
<#
    .SYNOPSIS

        Creates an in-memory struct for use in your PowerShell session.

        Author: Matthew Graeber (@mattifestation)
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: field

    .DESCRIPTION

        The 'struct' function facilitates the creation of structs entirely in
        memory using as close to a "C style" as PowerShell will allow. Struct
        fields are specified using a hashtable where each field of the struct
        is comprosed of the order in which it should be defined, its .NET
        type, and optionally, its offset and special marshaling attributes.

        One of the features of 'struct' is that after your struct is defined,
        it will come with a built-in GetSize method as well as an explicit
        converter so that you can easily cast an IntPtr to the struct without
        relying upon calling SizeOf and/or PtrToStructure in the Marshal
        class.

    .PARAMETER Module

        The in-memory module that will host the struct. Use
        New-InMemoryModule to define an in-memory module.

    .PARAMETER FullName

        The fully-qualified name of the struct.

    .PARAMETER StructFields

        A hashtable of fields. Use the 'field' helper function to ease
        defining each field.

    .PARAMETER PackingSize

        Specifies the memory alignment of fields.

    .PARAMETER ExplicitLayout

        Indicates that an explicit offset for each field will be specified.

    .EXAMPLE

        $Mod = New-InMemoryModule -ModuleName Win32

        $ImageDosSignature = psenum $Mod PE.IMAGE_DOS_SIGNATURE UInt16 @{
            DOS_SIGNATURE =    0x5A4D
            OS2_SIGNATURE =    0x454E
            OS2_SIGNATURE_LE = 0x454C
            VXD_SIGNATURE =    0x454C
        }

        $ImageDosHeader = struct $Mod PE.IMAGE_DOS_HEADER @{
            e_magic =    field 0 $ImageDosSignature
            e_cblp =     field 1 UInt16
            e_cp =       field 2 UInt16
            e_crlc =     field 3 UInt16
            e_cparhdr =  field 4 UInt16
            e_minalloc = field 5 UInt16
            e_maxalloc = field 6 UInt16
            e_ss =       field 7 UInt16
            e_sp =       field 8 UInt16
            e_csum =     field 9 UInt16
            e_ip =       field 10 UInt16
            e_cs =       field 11 UInt16
            e_lfarlc =   field 12 UInt16
            e_ovno =     field 13 UInt16
            e_res =      field 14 UInt16[] -MarshalAs @('ByValArray', 4)
            e_oemid =    field 15 UInt16
            e_oeminfo =  field 16 UInt16
            e_res2 =     field 17 UInt16[] -MarshalAs @('ByValArray', 10)
            e_lfanew =   field 18 Int32
        }

        # Example of using an explicit layout in order to create a union.
        $TestUnion = struct $Mod TestUnion @{
            field1 = field 0 UInt32 0
            field2 = field 1 IntPtr 0
        } -ExplicitLayout

    .NOTES

        PowerShell purists may disagree with the naming of this function but
        again, this was developed in such a way so as to emulate a "C style"
        definition as closely as possible. Sorry, I'm not going to name it
        New-Struct. :P
#>

    [OutputType([Type])]
    Param
    (
        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
        $Module,

        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FullName,

        [Parameter(Position = 3, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $StructFields,

        [Reflection.Emit.PackingSize]
        $PackingSize = [Reflection.Emit.PackingSize]::Unspecified,

        [Switch]
        $ExplicitLayout
    )

    if ($Module -is [Reflection.Assembly])
    {
        return ($Module.GetType($FullName))
    }

    [Reflection.TypeAttributes] $StructAttributes = 'AnsiClass,
        Class,
        Public,
        Sealed,
        BeforeFieldInit'

    if ($ExplicitLayout)
    {
        $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::ExplicitLayout
    }
    else
    {
        $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::SequentialLayout
    }

    $StructBuilder = $Module.DefineType($FullName, $StructAttributes, [ValueType], $PackingSize)
    $ConstructorInfo = [Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
    $SizeConst = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))

    $Fields = New-Object Hashtable[]($StructFields.Count)

    # Sort each field according to the orders specified
    # Unfortunately, PSv2 doesn't have the luxury of the
    # hashtable [Ordered] accelerator.
    ForEach ($Field in $StructFields.Keys)
    {
        $Index = $StructFields[$Field]['Position']
        $Fields[$Index] = @{FieldName = $Field; Properties = $StructFields[$Field]}
    }

    ForEach ($Field in $Fields)
    {
        $FieldName = $Field['FieldName']
        $FieldProp = $Field['Properties']

        $Offset = $FieldProp['Offset']
        $Type = $FieldProp['Type']
        $MarshalAs = $FieldProp['MarshalAs']

        $NewField = $StructBuilder.DefineField($FieldName, $Type, 'Public')

        if ($MarshalAs)
        {
            $UnmanagedType = $MarshalAs[0] -as ([Runtime.InteropServices.UnmanagedType])
            if ($MarshalAs[1])
            {
                $Size = $MarshalAs[1]
                $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo,
                    $UnmanagedType, $SizeConst, @($Size))
            }
            else
            {
                $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, [Object[]] @($UnmanagedType))
            }

            $NewField.SetCustomAttribute($AttribBuilder)
        }

        if ($ExplicitLayout) { $NewField.SetOffset($Offset) }
    }

    # Make the struct aware of its own size.
    # No more having to call [Runtime.InteropServices.Marshal]::SizeOf!
    $SizeMethod = $StructBuilder.DefineMethod('GetSize',
        'Public, Static',
        [Int],
        [Type[]] @())
    $ILGenerator = $SizeMethod.GetILGenerator()
    # Thanks for the help, Jason Shirk!
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
        [Type].GetMethod('GetTypeFromHandle'))
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
        [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [Type[]] @([Type])))
    $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ret)

    # Allow for explicit casting from an IntPtr
    # No more having to call [Runtime.InteropServices.Marshal]::PtrToStructure!
    $ImplicitConverter = $StructBuilder.DefineMethod('op_Implicit',
        'PrivateScope, Public, Static, HideBySig, SpecialName',
        $StructBuilder,
        [Type[]] @([IntPtr]))
    $ILGenerator2 = $ImplicitConverter.GetILGenerator()
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Nop)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldarg_0)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
        [Type].GetMethod('GetTypeFromHandle'))
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
        [Runtime.InteropServices.Marshal].GetMethod('PtrToStructure', [Type[]] @([IntPtr], [Type])))
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Unbox_Any, $StructBuilder)
    $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ret)

    $StructBuilder.CreateType()
}


function Test-EmailAddressFormat {
    [CmdletBinding()]
    param(
        [parameter(Position=0, HelpMessage='String to validate email address format.')]
        [string]$emailaddress
    )
    $emailregex = "[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
    if ($emailaddress -imatch $emailregex ) {
        return $true
    }
    else {
        return $false
    }
}


function Test-UserSIDFormat {
    [CmdletBinding()]
    param(
        [parameter(Position=0, Mandatory=$True, HelpMessage='String to validate is in user SID format.')]
        [string]$SID
    )
    $sidregex = "^S-\d-\d+-(\d+-){1,14}\d+$"
    if ($SID -imatch $sidregex ) {
        return $true
    }
    else {
        return $false
    }
}


Function Validate-EmailAddress {
    param( 
        [Parameter(Mandatory=$true)]
        [string]$EmailAddress
    )
    try {
        $check = New-Object System.Net.Mail.MailAddress($EmailAddress)
        return $true
    }
    catch {
        return $false
    }
}


## PUBLIC MODULE FUNCTIONS AND DATA ##

function Connect-DSAD {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Connect-DSAD.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Convert-DSCSE.md
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



function Convert-DSUACProperty {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Convert-DSUACProperty.md
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$UACProperty
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Disable-DSObject.md
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
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Enable-DSObject.md
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
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Format-DSSearchFilterValue.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString
    )
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $SearchString = $SearchString.Replace('\', '\5c')
    $SearchString = $SearchString.Replace('*', '\2a')
    $SearchString = $SearchString.Replace('(', '\28')
    $SearchString = $SearchString.Replace(')', '\29')
    $SearchString = $SearchString.Replace('/', '\2f')
    $SearchString.Replace("`0", '\00')
}



function Get-DSADSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSADSchemaVersion.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSADSite.md
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
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSADSiteSubnet.md
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
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSComputer.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Computer','Name')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [switch]$Raw,

        [Parameter(HelpMessage='Only those trusted for delegation.')]
        [switch]$TrustedForDelegation,

        [Parameter(HelpMessage='Date to search for computers mofied on or after this date.')]
        [datetime]$ModifiedAfter,

        [Parameter(HelpMessage='Date to search for computers mofied on or before this date.')]
        [datetime]$ModifiedBefore,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedAfter,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedBefore,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnAfter,

        [Parameter(HelpMessage='Date to search for computers that logged on or after this date.')]
        [datetime]$LogOnBefore,

        [Parameter(HelpMessage='Filter by the specified operating systems.')]
        [SupportsWildcards()]
        [string[]]$OperatingSystem,

        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [switch]$Enabled,

        [Parameter(HelpMessage='Filter by the specified Service Principal Names.')]
        [SupportsWildcards()]
        [string[]]$SPN
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build filter
        $BaseFilter = 'objectCategory=Computer'
        $LDAPFilters = @()

        if ($Filter.Count -ge 1) {
            $LDAPFilters += "(&({0}))" -f ($Filter -join ')(')
        }

        # Filter for modification time
        if ($ModifiedAfter) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($ModifiedBefore) {
            $LDAPFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for creation time
        if ($CreatedAfter) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($CreatedBefore) {
            $LDAPFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for logon time
        if ($LogOnAfter) {
            $LDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
            #$LDAPFilters +=  "lastlogon>=$($LogOnAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($LogOnBefore) {
            $LDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
            #$LDAPFilters += "lastlogon<=$($LogOnBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter by Operating System
        if ($OperatingSystem.Count -ge 1) {
            $OSFilter = "|(operatingSystem={0})" -f ($OperatingSystem -join ')(operatingSystem=')
            $LDAPFilters += $OSFilter
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $LDAPFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter by Service Principal Name
        if ($SPN.Count -ge 1) {
           $SPNFilter = "|(servicePrincipalName={0})" -f ($SPN -join ')(servicePrincipalName=')
           $LDAPFilters += $SPNFilter
        }

        # Filter for hosts trusted for delegation.
        if ($TrustedForDelegation) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }
    }

    process {
        # Process the last filters here to keep them separated in case they are being passed via the pipeline
        $FinalLDAPFilters = $LDAPFilters
        if ($Identity) {
            $FinalLDAPFilters += "name=$($Identity)"
        }
        else {
            $FinalLDAPFilters += "name=*"
        }

        $FinalLDAPFilters = @($FinalLDAPFilters | Select-Object -Unique)
        if ($ChangeLogicOrder) {
            # Join filters with logical OR
            $FinalFilter = "(&($BaseFilter)(|({0})))" -f ($FinalLDAPFilters -join ')(')
        }
        else {
            # Join filters with logical AND
            $FinalFilter = "(&($BaseFilter)(&({0})))" -f ($FinalLDAPFilters -join ')(')
        }
        Write-Verbose "$($FunctionName): Searching with filter: $FinalFilter"

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            Filter = $FinalFilter
            Properties = $Properties
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }
        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }
        if ($IncludeAllProperties) {
            $SearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $SearcherParams.DontJoinAttributeValues = $true
        }
        if ($Raw) {
            $SearcherParams.Raw = $true
        }
        Get-DSObject @SearcherParams
    }
}



function Get-DSConfigPartitionObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSConfigPartitionObject.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(Position = 2)]
        [string]$SearchPath,

        [Parameter(Position = 3)]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter(Position = 4)]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Base'
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."
    }

    process {
        $RootDSE = Get-DSDirectoryEntry -DistinguishedName 'rootDSE' -ComputerName $ComputerName -Credential $Credential

        if ($SearchPath) {
            Get-DSObject -SearchRoot "$SearchPath,$($rootDSE.configurationNamingContext)" -Properties $Properties -ComputerName $ComputerName -Credential $Credential -SearchScope:$SearchScope
        }
        else {
            Get-DSObject -SearchRoot "$($rootDSE.configurationNamingContext)" -Properties $Properties -ComputerName $ComputerName -Credential $Credential -SearchScope:$SearchScope
        }
    }
}



function Get-DSCurrentConnectedDomain {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSCurrentConnectedDomain.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSCurrentConnectedForest.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSCurrentConnectedSchema.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSCurrentConnectionStatus.md
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



function Get-DSDirectoryContext {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSDirectoryContext.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSDirectoryEntry.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [Alias('DN')]
        [string]$DistinguishedName,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [ValidateSet('LDAP', 'GC')]
        [string]$PathType = 'LDAP'
    )

    Begin {
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
                    #[adsi]''
                    New-Object -TypeName System.DirectoryServices.DirectoryEntry
                }
                else {
                    #[adsi]"$($PathType.ToUpper())://$($DistinguishedName)"
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSDirectorySearcher.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter = 'name=*',

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $ADConnectState = Get-CredentialState -Credential $Credential -ComputerName $ComputerName
        $SplitCreds = Split-Credential -Credential $Credential
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

        if (-not [string]::IsNullOrEmpty($Filter)) {
            Write-Verbose "$($FunctionName): Joining ldap filters, total filters = $($Filter.Count)."
            $LDAP = "(&({0}))" -f ($Filter -join ')(')
            Write-Verbose "$($FunctionName): LDAP filter = $LDAP"
        }

        $objSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ArgumentList @($domObj, $LDAP, $Properties) -Property @{
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSDomain.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name','Domain','DomainName')]
        [string]$Identity = ($Script:CurrentDomain).name,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSExchangeFederation.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        $Props_ExchFeds = @(
            'Name',
            'msExchFedIsEnabled',
            'msExchFedDomainNames',
            'msExchFedEnabledActions',
            'msExchFedTargetApplicationURI',
            'msExchFedTargetAutodiscoverEPR',
            'msExchVersion'
        )
        $ConfigNamingContext = (Get-DSDirectoryEntry -DistinguishedName 'rootDSE' @DSParams).configurationNamingContext
        $Path_ExchangeOrg = "LDAP://CN=Microsoft Exchange,CN=Services,$($ConfigNamingContext)"
        $ExchangeFederations = @()
    }

    end {
        if (Test-DSObjectPath -Path $Path_ExchangeOrg @DSParams) {

            $ExchOrgs = @(Get-DSObject -Filter 'objectClass=msExchOrganizationContainer' -SearchRoot $Path_ExchangeOrg -SearchScope:SubTree -Properties $Props_ExchOrgs @DSParams)

            ForEach ($ExchOrg in $ExchOrgs) {
                $ExchServers = @(Get-DSObject -Filter 'objectCategory=msExchExchangeServer' -SearchRoot $ExchOrg.distinguishedname  -SearchScope:SubTree -Properties $Props_ExchServers  @DSParams)

                # Get all found Exchange federations
                $ExchangeFeds = @(Get-DSObject -Filter 'objectCategory=msExchFedSharingRelationship' -SearchRoot "LDAP://CN=Federation,$([string]$ExchOrg.distinguishedname)"  -SearchScope:SubTree -Properties $Props_ExchFeds)
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSExchangeSchemaVersion.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSExchangeServer.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
                    New-Object -TypeName PSObject -Property @{
                        Organization = $ExchOrg.Name
                        AdminGroup = $AdminGroup
                        Name = $ExchServer.adminDisplayName
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSForest.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name','Forest','ForestName')]
        [string]$Identity = ($Script:CurrentForest).name,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSForestTrust.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name','Forest','ForestName')]
        [string]$Identity = ($Script:CurrentForest).name,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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



function Get-DSGPO {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSGPO.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [switch]$Raw,

        [Parameter(HelpMessage='Date to search for computers mofied on or after this date.')]
        [datetime]$ModifiedAfter,

        [Parameter(HelpMessage='Date to search for computers mofied on or before this date.')]
        [datetime]$ModifiedBefore,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedAfter,

        [Parameter(HelpMessage='Date to search for computers created on or after this date.')]
        [datetime]$CreatedBefore,

        [Parameter()]
        [string[]]$UserExtension,

        [Parameter()]
        [string[]]$MachineExtension
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Base filter is the part of this filter that must always be met.
        $BaseFilter = 'objectClass=groupPolicyContainer'
        $LDAPFilters = @()

        # Passed filters are joined with AND logic
        if ($Filter.Count -ge 1) {
            $LDAPFilters += "(&({0}))" -f ($Filter -join ')(')
        }

        # Filter for modification time
        if ($ModifiedAfter) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($ModifiedBefore) {
            $LDAPFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for creation time
        if ($CreatedAfter) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($CreatedBefore) {
            $LDAPFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter on User Extension Filter.
        if ($UserExtension) {
            $LDAPFilters += "|(gpcuserextensionnames=*{0})" -f ($UserExtension -join '*)(gpcuserextensionnames=*')
        }

        # Filter on Machine Extension Filter.
        if ($MachineExtension) {
            $LDAPFilters += "|(gpcmachineextensionnames=*{0})" -f ($UserExtension -join '*)(gpcmachineextensionnames=*')
        }
    }

    process {
        # Process the last filters here to keep them separated in case they are being passed via the pipeline
        $FinalLDAPFilters = $LDAPFilters
        if ($Identity) {
            $FinalLDAPFilters += "|(name=$($Identity))(displayname=$($Identity))"
        }
        else {
            $FinalLDAPFilters += "name=*"
        }

        $FinalLDAPFilters = $FinalLDAPFilters | Select -Unique
        if ($ChangeLogicOrder) {
            # Join filters with logical OR
            $FinalFilter = "(&($BaseFilter)(|({0})))" -f ($FinalLDAPFilters -join ')(')
        }
        else {
            # Join filters with logical AND
            $FinalFilter = "(&($BaseFilter)(&({0})))" -f ($FinalLDAPFilters -join ')(')
        }

        Write-Verbose "$($FunctionName): Searching with filter: $FinalFilter"

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            Filter = $FinalFilter
            Properties = $Properties
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }
        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }
        if ($IncludeAllProperties) {
            $SearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $SearcherParams.DontJoinAttributeValues = $true
        }
        if ($Raw) {
            $SearcherParams.Raw = $true
        }

        Get-DSObject @SearcherParams
    }
}



function Get-DSGroup {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSGroup.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Group','Name')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [datetime]$ModifiedAfter,

        [Parameter()]
        [datetime]$ModifiedBefore,

        [Parameter()]
        [datetime]$CreatedAfter,

        [Parameter()]
        [datetime]$CreatedBefore,

        [Parameter()]
        [ValidateSet('Security','Distribution')]
        [string]$Category,

        [Parameter()]
        [switch]$AdminCount
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Build filter
        $CompLDAPFilter = 'objectCategory=Group'
        $LDAPFilters = @()

        if ($Filter.Count -ge 1) {
            $LDAPFilters += "(&({0}))" -f ($Filter -join ')(')
        }

        # Filter for modification time
        if ($ModifiedAfter -and $ModifiedBefore) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ')))(whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($ModifiedAfter) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($ModifiedBefore) {
            $LDAPFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for creation time
        if ($CreatedAfter -and $CreatedBefore) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ')))(whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($CreatedAfter) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        elseif ($CreatedBefore) {
            $LDAPFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        if ($Identity) {
            $Identity = Format-ADSearchFilterValue -String $Identity
            $LDAPFilters += "|(name=$($Identity))(sAMAccountName=$($Identity))(cn=$($Identity))"
        }
        else {
            $LDAPFilters += 'name=*'
        }
       # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $LDAPFilters += "admincount>=1"
        }

        # Filter by category
        if ($Category) {
            switch ($category) {
                'Distribution' {
                    $LDAPFilters += '!(groupType:1.2.840.113556.1.4.803:=2147483648)'
                }
                'Security' {
                    $LDAPFilters += 'groupType:1.2.840.113556.1.4.803:=2147483648'
                }
            }
        }

        $LDAPFilters = $LDAPFilters | Select -Unique

        if ($ChangeLogicOrder) {
            $GroupFilter = "(&($CompLDAPFilter)(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            $GroupFilter = "(&($CompLDAPFilter)(&({0})))" -f ($LDAPFilters -join ')(')
        }
    }

    process {
        Write-Verbose "$($FunctionName): Searching with filter: $GroupFilter"

         $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            Filter = $GroupFilter
            Properties = $Properties
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }
        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }
        if ($IncludeAllProperties) {
            $SearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $SearcherParams.DontJoinAttributeValues = $true
        }

        if ($Raw) {
            $SearcherParams.Raw = $true
        }

        Get-DSObject @SearcherParams
    }
}



function Get-DSGroupMember {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSGroupMember.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name','Group','GroupName')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$Recurse
    )

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $BaseSearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }

        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $BaseSearcherParams.Tombstone = $true
        }
    }

    process {
        Write-Verbose "$($FunctionName): Trying to find the group - $Identity"
        try {
            $Identity = Format-DSSearchFilterValue -String $Identity
            $Group = Get-DSGroup @BaseSearcherParams -Identity $Identity -Properties @('distinguishedname','samaccountname')
        }
        catch {
            throw
            Write-Error "$($FunctionName): Error trying to find the group - $Identity"
        }

        if ($Group.distinguishedname -eq $null) {
            Write-Error "$($FunctionName): No group found with the name of $Identity"
            return
        }

        $GroupSearcherParams = $BaseSearcherParams.Clone()

        if ($Properties.count -ge 1) {
            $GroupSearcherParams.Properties = $Properties
        }
        if ($IncludeAllProperties) {
            $GroupSearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $GroupSearcherParams.DontJoinAttributeValues = $true
        }
        if ($Raw) {
            $GroupSearcherParams.Raw = $true
        }

        $Filter = @()
        if ($Recurse) {
            $Filter += "memberof:1.2.840.113556.1.4.1941:=$($Group.distinguishedname)"
        }
        else {
            $Filter += "memberof=$($Group.distinguishedname)"
        }

        Get-DSObject @GroupSearcherParams -Filter $Filter
    }
}



function Get-DSGUIDMap {
<#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSGUIDMap.md
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
    )

    $GUIDs = @{'00000000-0000-0000-0000-000000000000' = 'All'}

    $SchemaPath = (Get-DSCurrentConnectedForest).schema.name
    $SchemaSearcher = Get-DSDirectorySearcher -Filter "(schemaIDGUID=*)" -SearchRoot $SchemaPath -Properties * -ComputerName $ComputerName -Credential $Credential
    $SchemaSearcher.FindAll() | Foreach-Object {
        # convert the GUID
        $GUIDs[(New-Object Guid (,$_.properties.schemaidguid[0])).Guid] = $_.properties.name[0]
    }

    $RightsPath = $SchemaPath.replace("Schema","Extended-Rights")
    $RightsSearcher = Get-DSDirectorySearcher -Filter "(objectClass=controlAccessRight)" -SearchRoot $RightsPath  -Properties * -ComputerName $ComputerName -Credential $Credential
    $RightsSearcher.FindAll() | ForEach-Object {
        # convert the GUID
        $GUIDs[$_.properties.rightsguid[0].toString()] = $_.properties.name[0]
    }

    $GUIDs
}



function Get-DSLastLDAPFilter {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSLastLDAPFilter.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSLastSearchSetting.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSObject.md
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [SupportsWildcards()]
        [Alias('Name')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$ExpandUAC,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [ValidateSet('psobject', 'directoryentry', 'searcher')]
        [string]$ResultsAs = 'psobject'
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Credential = $Credential
            Properties = $Properties
            SecurityMask = $SecurityMask
        }
    }
    Process {
        # Build the filter
        $LDAPFilters = Get-CommonIDLDAPFilter -Identity $Identity -Filter $Filter
        if (-not [string]::IsNullOrEmpty($Identity)) {
            # If an identity was passed then change to or logic
            $ChangeLogicOrder = $true
        }

        if ($ChangeLogicOrder) {
            Write-Verbose "$($FunctionName): Combining filters with OR logic."
            $SearcherParams.Filter = "(&(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            Write-Verbose "$($FunctionName): Combining filters with AND logic."
            $SearcherParams.Filter = "(&(&({0})))" -f ($LDAPFilters -join ')(')
        }

        if ($IncludeAllProperties) {
            Write-Verbose "$($FunctionName): Including all properties. Any passed properties will be ignored."
            $SearcherParams.Properties = '*'
        }

        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }

        # If a limit is set then use it to limit our results, otherwise use the page size (which doesn't limit results)
        if ($Limit -ne 0) {
            $SearcherParams.Limit = $Limit
        }
        else {
            $SearcherParams.PageSize = $PageSize
        }

        # Store the search settings for later inspection if required
        $Script:LastSearchSetting = $SearcherParams

        Write-Verbose "$($FunctionName): Searching with filter: $LDAPFilter"

        $objSearcher = Get-DSDirectorySearcher @SearcherParams
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
                        if ($Prop -ne $null) {
                            if (-not $Raw) {
                                switch ($Prop) {
                                    'objectguid' {
                                        Write-Verbose "$($FunctionName): Reformatting objectguid"
                                        $Val = [guid]$Val[0]
                                    }
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
                        if ($IncludeAllProperties) {
                            if (-not ($Script:__ad_schema_info.ContainsKey($ObjClass))) {
                                Write-Verbose "$($FunctionName): Storing schema attributes for $ObjClass for the first time"
                                Write-Verbose "$($FunctionName): Object class being queried for in the schema = $objClass"
                                ($Script:__ad_schema_info).$ObjClass = @(((Get-DSCurrentConnectedSchema).FindClass($objClass)).OptionalProperties).Name
                            }
                            else {
                                Write-Verbose "$($FunctionName): $ObjClass schema properties already loaded"
                            }

                            ($Script:__ad_schema_info).$ObjClass | Foreach {
                                if (-not ($ObjectProps.ContainsKey($_))) {
                                    $ObjectProps.$_ = $null
                                }
                            }
                        }

                        New-Object PSObject -Property $ObjectProps | Select-Object $Properties
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



function Get-DSOCSSchemaVersion {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSOCSSchemaVersion.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSOCSTopology.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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



function Get-DSOptionalFeatures {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSOptionalFeatures.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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



function Get-DSPageSize {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSPageSize.md
    #>
    [CmdletBinding()]
    param ()
    
    $FunctionName = $MyInvocation.MyCommand.Name
    Write-Verbose "$($FunctionName): Begin."

    return $Script:PageSize
}



function Get-DSSCCMServer {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSSCCMServer.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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

            $SCCMData = @(Get-DSObject -SearchRoot $SysManageContext @DSParams -Filter 'objectClass=mSSMSManagementPoint' -Properties mSSMSCapabilities,mSSMSMPName,dNSHostName,mSSMSSiteCode,mSSMSVersion,mSSMSDefaultMP,mSSMSDeviceManagementPoint)

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
                    Version = $SCCMVer
                    MPName = $SCCM.mSSMSMPName
                    FQDN = $SCCM.dNSHostName
                    SiteCode = $SCCM.mSSMSSiteCode
                    SMSVersion = $SCCM.mSSMSVersion
                    DefaultMP = $SCCM.mSSMSDefaultMP
                    DeviceMP = $SCCM.mSSMSDeviceManagementPoint
                }
            }
        }
    }
}



function Get-DSSchema {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSSchema.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [Alias('Creds')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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



function Get-DSTombstoneLifetime {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSTombstoneLifetime.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 1)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Get-DSUser.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('User','Name')]
        [string]$Identity,

        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter()]
        [Alias('SizeLimit')]
        [int]$Limit = 0,

        [Parameter()]
        [string]$SearchRoot,

        [Parameter()]
        [string[]]$Filter,

        [Parameter()]
        [string[]]$Properties = @('Name','ADSPath'),

        [Parameter()]
        [int]$PageSize = $Script:PageSize,

        [Parameter()]
        [ValidateSet('Subtree', 'OneLevel', 'Base')]
        [string]$SearchScope = 'Subtree',

        [Parameter()]
        [ValidateSet('None', 'Dacl', 'Group', 'Owner', 'Sacl')]
        [string]$SecurityMask = 'None',

        [Parameter()]
        [switch]$TombStone,

        [Parameter()]
        [switch]$DontJoinAttributeValues,

        [Parameter()]
        [switch]$IncludeAllProperties,

        [Parameter()]
        [switch]$ChangeLogicOrder,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [switch]$ExpandUAC,

        [Parameter()]
        [switch]$DotNotAllowDelegation,

        [Parameter()]
        [switch]$AllowDelegation,

        [Parameter()]
        [switch]$UnconstrainedDelegation,

        [Parameter()]
        [datetime]$ModifiedAfter,

        [Parameter()]
        [datetime]$ModifiedBefore,

        [Parameter()]
        [datetime]$CreatedAfter,

        [Parameter()]
        [datetime]$CreatedBefore,

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

    begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        # Most efficient user ldap filter for user accounts: http://www.selfadsi.org/extended-ad/search-user-accounts.htm
        $BaseFilter = 'sAMAccountType=805306368'
        $LDAPFilters = @()

        if ($Filter.Count -ge 1) {
            $LDAPFilters += "(&({0}))" -f ($Filter -join ')(')
        }

        # Filter for modification time
        if ($ModifiedAfter) {
            $LDAPFilters += "whenChanged>=$($ModifiedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($ModifiedBefore) {
            $LDAPFilters += "whenChanged<=$($ModifiedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for creation time
        if ($CreatedAfter) {
            $LDAPFilters +=  "whencreated>=$($CreatedAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($CreatedBefore) {
            $LDAPFilters += "whencreated<=$($CreatedBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        if ($LogOnAfter) {
            $LDAPFilters += "lastlogontimestamp>=$($LogOnAfter.TofileTime())"
            #$LDAPFilters +=  "lastlogon>=$($LogOnAfter.ToString('yyyyMMddhhmmss.sZ'))"
        }
        if ($LogOnBefore) {
            $LDAPFilters += "lastlogontimestamp<=$($LogOnBefore.TofileTime())"
            #$LDAPFilters += "lastlogon<=$($LogOnBefore.ToString('yyyyMMddhhmmss.sZ'))"
        }

        # Filter for accounts that are marked as sensitive and can not be delegated.
        if ($DotNotAllowDelegation) {
            $LDAPFilters += 'userAccountControl:1.2.840.113556.1.4.803:=1048574'
        }

        if ($AllowDelegation) {
            # negation of "Accounts that are sensitive and not trusted for delegation"
            $LDAPFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=1048574)"
        }

        # User has unconstrained delegation set.
        if ($UnconstrainedDelegation) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=524288"
        }

        # Account is locked
        if ($Locked) {
            $LDAPFilters += 'lockoutTime>=1'
        }

        # Filter for accounts who do not requiere a password to logon.
        if ($NoPasswordRequired) {
            $LDAPFilters += 'userAccountControl:1.2.840.113556.1.4.803:=32'
        }

        # Filter for accounts whose password does not expires.
        if ($PasswordNeverExpires) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=65536"
        }

        # Filter for accounts that are disabled.
        if ($Disabled) {
            $LDAPFilters += "userAccountControl:1.2.840.113556.1.4.803:=2"
        }

        # Filter for accounts that are enabled.
        if ($Enabled) {
            $LDAPFilters += "!(userAccountControl:1.2.840.113556.1.4.803:=2)"
        }

        # Filter for accounts who have an adcmicount filed higher than 0.
        if ($AdminCount) {
            $LDAPFilters += "admincount>=1"
        }

        # Filter for accounts that have SPN set.
        if ($ServiceAccount) {
            $LDAPFilters += "servicePrincipalName=*"
        }

        # Filter whose users must change their passwords.
        if ($MustChangePassword) {
            $LDAPFilters += 'pwdLastSet=0'
        }

        $LDAPFilters = @($LDAPFilters | Select-Object -Unique)
        if ($ChangeLogicOrder) {
            $UserFilter = "(&($UserLDAPFilter)(|({0})))" -f ($LDAPFilters -join ')(')
        }
        else {
            $UserFilter = "(&($UserLDAPFilter)(&({0})))" -f ($LDAPFilters -join ')(')
        }
    }

    process {
        # Process the last filters here to keep them separated in case they are being passed via the pipeline
        $FinalLDAPFilters = $LDAPFilters

        if ($Identity) {
            $FinalLDAPFilters += "|(name=$($Identity))(sAMAccountName=$($Identity))(cn=$($Identity))(DisplayName=$($Identity))"
        }
        else {
            $FinalLDAPFilters += 'sAMAccountName=*'
        }

        $FinalLDAPFilters = @($FinalLDAPFilters | Select-Object -Unique)

        if ($ChangeLogicOrder) {
            # Join filters with logical OR
            $FinalFilter = "(&($BaseFilter)(|({0})))" -f ($FinalLDAPFilters -join ')(')
        }
        else {
            # Join filters with logical AND
            $FinalFilter = "(&($BaseFilter)(&({0})))" -f ($FinalLDAPFilters -join ')(')
        }

        Write-Verbose "$($FunctionName): Searching with filter: $FinalFilter"

        $SearcherParams = @{
            ComputerName = $ComputerName
            SearchRoot = $searchRoot
            SearchScope = $SearchScope
            Limit = $Limit
            Credential = $Credential
            Filter = $FinalFilter
            Properties = $Properties
            PageSize = $PageSize
            SecurityMask = $SecurityMask
        }
        if ($Tombstone) {
            Write-Verbose "$($FunctionName): Including tombstone items"
            $SearcherParams.Tombstone = $true
        }
        if ($IncludeAllProperties) {
            $SearcherParams.IncludeAllProperties = $true
        }
        if ($DontJoinAttributeValues) {
            $SearcherParams.DontJoinAttributeValues = $true
        }
        if ($ExpandUAC) {
            $SearcherParams.ExpandUAC = $true
        }
        if ($Raw) {
            $SearcherParams.Raw = $true
        }

        Get-DSObject @SearcherParams
    }
}



function Move-DSObject {
    <#
    .EXTERNALHELP PSAD-help.xml
    .LINK
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Move-DSObject.md
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium' )]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias('Name')]
        [string[]]$Identity,

        [Parameter(Position = 1)]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2)]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

        [Parameter(Position = 3)]
        [Alias('OU','TargetPath')]
        [string]$Destination,

        [Parameter(Position = 4, HelpMessage = 'Force move to OU without confirmation.')]
        [Switch]$Force
    )

    Begin {
        # Function initialization
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose "$($FunctionName): Begin."

        $Identities = @()

        $SearcherParams = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }

        # If the destination OU doesn't exist then there is nothing for us to do...
        if (-not (Test-DSObjectPath -Path $Destination @SearcherParams)) {
            Write-Error "$($FunctionName): Destination OU doesn't seem to exist: $Destination"
            return
        }
        Else {
            Write-Verbose "$($FunctionName): Retreiving DN of the OU at $Destination"
            $OU = Get-DSDirectoryEntry @SearcherParams -DistinguishedName $Destination
        }

        $SearcherParams.ReturnDirectoryEntry = $True
        $SearcherParams.ChangeLogicOrder = $True
        $YesToAll = $false
        $NoToAll = $false
    }

    Process {
        $Identities += $Identity
    }
    end {
        Foreach ($ID in $Identities) {
            $SearcherParams.Filter = @("distinguishedName=$ID","objectGUID=$ID","name=$ID","cn=$ID")
            Get-DSObject @SearcherParams | ForEach-Object {
                $Name = $_.Properties['name']
                Write-Verbose "$($FunctionName): Proccessing found object name: $Name"
                if ($pscmdlet.ShouldProcess("Move AD Object $Name to $Destination", "Move AD Object $Name to $Destination?","Moving AD Object $Name")) {
                    if ($Force -Or $PSCmdlet.ShouldContinue("Are you REALLY sure you want to move '$Name'?", "Moving AD Object $Name", [ref]$YesToAll, [ref]$NotoAll)) {
                        try {
                            ($_.GetDirectoryEntry()).MoveTo($OU)
                        }
                        catch {
                            throw $_
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Set-DSObject.md
    #>
    [CmdletBinding( SupportsShouldProcess=$True, ConfirmImpact='Medium', DefaultParameterSetName = 'Default' )]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='Default')]
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, ParameterSetName='MultiProperty')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias('Name')]
        [string]$Identity,

        [Parameter(Position = 1, ParameterSetName='Default')]
        [Parameter(Position = 1, ParameterSetName='MultiProperty')]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter(Position = 2, ParameterSetName='Default')]
        [Parameter(Position = 2, ParameterSetName='MultiProperty')]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,

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
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Set-DSPageSize.md
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
        https://github.com/zloeber/PSAD/tree/master/release/0.0.2/docs/Functions/Test-DSObjectPath.md
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [Alias('Server','ServerName')]
        [string]$ComputerName = $Script:CurrentServer,

        [Parameter()]
        [alias('Creds')]
        [Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential = $Script:CurrentCredential,
        
        [Parameter(Mandatory=$true)]
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




