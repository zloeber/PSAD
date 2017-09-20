---
Module Name: PSAD
Module Guid: 00000000-0000-0000-0000-000000000000
Download Help Link: https://github.com/zloeber/PSAD/release/PSAD/docs/PSAD.md
Help Version: 0.1.3
Locale: en-US
---

# PSAD Module
## Description
Advanced ADSI PowerShell Module

## PSAD Cmdlets
### [Add-DSGroupMember](Add-DSGroupMember.md)
Adds AD objects to a specified group.

### [Add-DSTranslatedUAC](Add-DSTranslatedUAC.md)
Enumerate and add additional properties for a user object for useraccountcontrol.

### [Connect-DSAD](Connect-DSAD.md)
Connect to active directory.

### [Convert-DSCSE](Convert-DSCSE.md)
Converts a GPO client side extension setting string of GUIDs to readable text.

### [Convert-DSName](Convert-DSName.md)
Translates Active Directory names between various formats.

### [Convert-DSUACProperty](Convert-DSUACProperty.md)
Takes the useraccesscontrol property, evaluates it, and spits out all set UAC properties

### [Disable-DSObject](Disable-DSObject.md)
Sets properties of an AD object

### [Enable-DSObject](Enable-DSObject.md)
Sets properties of an AD object

### [Format-DSSearchFilterValue](Format-DSSearchFilterValue.md)
Escapes Active Directory special characters from a string.

### [Get-DSAccountMembership](Get-DSAccountMembership.md)
Get account object group membership.

### [Get-DSADSchemaVersion](Get-DSADSchemaVersion.md)
Retreives the active directory schema version in human readable format.

### [Get-DSADSite](Get-DSADSite.md)
Retreives the AD site information

### [Get-DSADSiteSubnet](Get-DSADSiteSubnet.md)
Retreives the AD site information

### [Get-DSComputer](Get-DSComputer.md)
Get computer objects in a given directory service.

### [Get-DSConfigPartition](Get-DSConfigPartition.md)
Retrieves information about the configuration partition.

### [Get-DSCurrentConnectedDomain](Get-DSCurrentConnectedDomain.md)
Gets the currently connected domain object

### [Get-DSCurrentConnectedForest](Get-DSCurrentConnectedForest.md)
Gets the currently connected forest information.

### [Get-DSCurrentConnectedSchema](Get-DSCurrentConnectedSchema.md)
Gets the currently connected forest schema information.

### [Get-DSCurrentConnectionStatus](Get-DSCurrentConnectionStatus.md)
Validate if Connect-ActiveDirectory has been run successfully already. Returns True if so.

### [Get-DSDFS](Get-DSDFS.md)
Retreives the DFS AD information

### [Get-DSDFSR](Get-DSDFSR.md)
Retreives the DFSR AD information

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

### [Get-DSFRS](Get-DSFRS.md)
Retreives the FRS AD information

### [Get-DSGPO](Get-DSGPO.md)
Get computer objects in a given directory service.

### [Get-DSGPOPassword](Get-DSGPOPassword.md)
Retrieves the plaintext password and other information for accounts pushed through Group Policy Preferences.

### [Get-DSGroup](Get-DSGroup.md)
Get group objects in a given directory service.

### [Get-DSGroupMember](Get-DSGroupMember.md)
Return all members of a group.

### [Get-DSGUIDMap](Get-DSGUIDMap.md)
Retrieves the module internal GUIDMap hash (if it has been populated)

### [Get-DSLastLDAPFilter](Get-DSLastLDAPFilter.md)
Returns the last used LDAP filter.

### [Get-DSLastSearchSetting](Get-DSLastSearchSetting.md)
Returns the last used directory search settings.

### [Get-DSObject](Get-DSObject.md)
Get AD objects of any kind.

### [Get-DSObjectACL](Get-DSObjectACL.md)
Get the security permissions for a given DN.

### [Get-DSOCSSchemaVersion](Get-DSOCSSchemaVersion.md)
Retreives the OCS/Skype/Lync schema version and configuraiton partition location from active directory.

### [Get-DSOCSTopology](Get-DSOCSTopology.md)
Retreives the OCS/Skype/Lync information from active directory.

### [Get-DSOptionalFeature](Get-DSOptionalFeature.md)
Retreives the optional directory features that are configured (such as the recycle bin)

### [Get-DSOrganizationalUnit](Get-DSOrganizationalUnit.md)
Get OU objects in a given directory service.

### [Get-DSPageSize](Get-DSPageSize.md)
Returns module variable containing the currently used page size for AD queries.

### [Get-DSRootDSE](Get-DSRootDSE.md)
Retrieves the RootDSE of a forest.

### [Get-DSSCCMManagementPoint](Get-DSSCCMManagementPoint.md)
Retreives the SCCM AD information

### [Get-DSSCCMServiceLocatorPoint](Get-DSSCCMServiceLocatorPoint.md)
Retreives the SCCM service locator point AD information

### [Get-DSSchema](Get-DSSchema.md)
Get information of the schema for the existing forest.

### [Get-DSSID](Get-DSSID.md)
Converts a given user/group name to a security identifier (SID).

### [Get-DSTombstoneLifetime](Get-DSTombstoneLifetime.md)
Retreives the forest tombstone lifetime in days.

### [Get-DSUser](Get-DSUser.md)
Get Account objects in a given directory service.

### [Move-DSObject](Move-DSObject.md)
Moves AD objects to a destination OU.

### [Remove-DSGroupMember](Remove-DSGroupMember.md)
Removes AD objects to a specified group.

### [Set-DSObject](Set-DSObject.md)
Sets properties of an AD object

### [Set-DSPageSize](Set-DSPageSize.md)
Sets module variable containing the currently used page size for AD queries.

### [Test-DSObjectPath](Test-DSObjectPath.md)
A helper function to validate if an object path exists in AD.


