# PSAD
PowerShell Advanced ADSI Module

Project Site: [https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

## What is PSAD?
PowerShell Advanced ADSI Module

## Why use the PSAD Module?
This module was written to be blazingly fast, allow remote domain (alternate credential) use across all functions, and serve as a discovery/learning tool for LDAP filters. If that appeals to you then this module might server you well.

### Features
- Ability to use alternate credentials within the same forest (or targeting a different forest)
- Very easy to expand upon
- Few 'translated' fields (so you are forced to become more familiar with actual LDAP properties)
- Simple but useful helper functions are included for thing like getting the tombstone lifetime, forest functional levels, OCS/Lync/Skype topologies, and Exchange servers/versions.

## Installation
PSAD is available on the [PowerShell Gallery](https://www.powershellgallery.com/packages/PSAD/).

To Inspect:
```powershell
Save-Module -Name PSAD -Path <path>
```
To install:
```powershell
Install-Module -Name PSAD -Scope CurrentUser
```

## Contributing
[Notes on contributing to this project](Contributing.md)

## Release Notes
[Version release notes](ReleaseNotes.md)

## Acknowledgements
[Other projects or sources of inspiration](Acknowledgements.md)
