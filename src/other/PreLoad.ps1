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