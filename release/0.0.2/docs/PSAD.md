---
Module Name: PSAD
Module Guid: 00000000-0000-0000-0000-000000000000
Download Help Link: https://github.com/zloeber/PSAD/release/PSAD/docs/PSAD.md
Help Version: 0.0.3
Locale: en-US
---

# PSAD Module
## Description
Advanced ADSI PowerShell Module

## PSAD Cmdlets
### [Connect-DSAD](Connect-DSAD.md)
Connect to active directory.

### [Convert-DSCSE](Convert-DSCSE.md)
Converts a GPO client side extension setting string of GUIDs to readable text.

### [Convert-DSUACProperty](Convert-DSUACProperty.md)
Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties

### [Disable-DSObject](Disable-DSObject.md)
Sets properties of an AD object

### [Enable-DSObject](Enable-DSObject.md)
Sets properties of an AD object

### [Format-DSSearchFilterValue](Format-DSSearchFilterValue.md)
Escapes Active Directory special characters from a string.

### [Get-DSADSchemaVersion](Get-DSADSchemaVersion.md)
Retreives the active directory schema version in human readable format.

### [Get-DSADSite](Get-DSADSite.md)
Retreives the AD site information

### [Get-DSADSiteSubnet](Get-DSADSiteSubnet.md)
Retreives the AD site information

### [Get-DSComputer](Get-DSComputer.md)
Get computer objects in a given directory service.

### [Get-DSConfigPartitionObject](Get-DSConfigPartitionObject.md)
A helper function for retreiving a configuration partition object.

### [Get-DSCurrentConnectedDomain](Get-DSCurrentConnectedDomain.md)
Gets the currently connected domain object

### [Get-DSCurrentConnectedForest](Get-DSCurrentConnectedForest.md)
Gets the currently connected forest information.

### [Get-DSCurrentConnectedSchema](Get-DSCurrentConnectedSchema.md)
Gets the currently connected forest schema information.

### [Get-DSCurrentConnectionStatus](Get-DSCurrentConnectionStatus.md)
Validate if Connect-ActiveDirectory has been run successfully already. Returns True if so.

### [Get-DSDirectoryContext](Get-DSDirectoryContext.md)
Get a DirectoryContext object for a specified context.

### [Get-DSDirectoryEntry](Get-DSDirectoryEntry.md)
Get a DirectoryEntry object for a specified distinguished name.

### [Get-DSDirectorySearcher](Get-DSDirectorySearcher.md)
Get a diresctory searcher object fro a given domain.

### [Get-DSDomain](Get-DSDomain.md)
Retrieve an ADSI domain object.

### [Get-DSExchangeFederation](Get-DSExchangeFederation.md)
Retreives Exchange federations from active directory.

### [Get-DSExchangeSchemaVersion](Get-DSExchangeSchemaVersion.md)
Retreives the Exchange schema version in human readable format.

### [Get-DSExchangeServer](Get-DSExchangeServer.md)
Retreives Exchange servers from active directory.

### [Get-DSForest](Get-DSForest.md)
Retrieve an ADSI forest object.

### [Get-DSForestTrust](Get-DSForestTrust.md)
Retrieve an ADSI forest object.

### [Get-DSGPO](Get-DSGPO.md)
Retreives GPOs as seen by Active Directory

### [Get-DSGroup](Get-DSGroup.md)
Get computer objects in a given directory service.

### [Get-DSGroupMember](Get-DSGroupMember.md)
Return all members of a group.

### [Get-DSGUIDMap](Get-DSGUIDMap.md)
Helper to build a hash table of [GUID] -> resolved names

### [Get-DSLastLDAPFilter](Get-DSLastLDAPFilter.md)
Returns the last used LDAP filter.

### [Get-DSLastSearchSetting](Get-DSLastSearchSetting.md)
Returns the last used directory search settings.

### [Get-DSObject](Get-DSObject.md)
Get AD objects of any kind.

### [Get-DSOCSSchemaVersion](Get-DSOCSSchemaVersion.md)
Retreives the OCS/Skype/Lync schema version and configuraiton partition location from active directory.

### [Get-DSOCSTopology](Get-DSOCSTopology.md)
Retreives the OCS/Skype/Lync information from active directory.

### [Get-DSOptionalFeatures](Get-DSOptionalFeatures.md)
Retreives the optional directory features that are configured (such as the recycle bin)

### [Get-DSPageSize](Get-DSPageSize.md)
Returns module variable containing the currently used page size for AD queries.

### [Get-DSSCCMServer](Get-DSSCCMServer.md)
Retreives the SCCM AD information

### [Get-DSSchema](Get-DSSchema.md)
Get information of the schema for the existing forest.

### [Get-DSTombstoneLifetime](Get-DSTombstoneLifetime.md)
Retreives the forest tombstone lifetime in days.

### [Get-DSUser](Get-DSUser.md)
Get Account objects in a given directory service.

### [Move-DSObject](Move-DSObject.md)
Move AD objects to another OU.

### [Set-DSObject](Set-DSObject.md)
Sets properties of an AD object

### [Set-DSPageSize](Set-DSPageSize.md)
Sets module variable containing the currently used page size for AD queries.

### [Test-DSObjectPath](Test-DSObjectPath.md)
A helper function to validate if an object path exists in AD.



