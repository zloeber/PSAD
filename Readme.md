# PSAD

And Advanced ADSI PowerShell Module.

## Description

PSAD stands for PowerShell Active Directory. This is an advanced ADSI powerShell module with a few premises. The first premise is that nothing is 'dumbed down'. So AD property names are not dumbed down or transposed into friendlier names for input or output as other modules tend to do. Another premise is that you should be able to use this module in 4 different contexts:
- As the current domain user
- As the current domain user against another server
- As another domain user
- As another domain user against another server

This allows for both casual local domain users and for non-domain joined workstations with alternate credentials to perform Active Directory discovery.

## Introduction

There will be no parameters in functions like -FirstName as that is actually the givenname property in AD, LastName would be sn (surname), and so on. In fact, you will have to pass all the properties you want to see in your output for every command. So a standard command to get an AD user would need to look like the following to show the first and last name:

```
get-dsuser zloeber -Properties 'sn','givenname'
```

While this may seem like needless difficult overhead I believe it encourages a stronger knowledge of Active Directory. Much of the included parameters used in the Get commands are automatically rewritten as LDAP filters and there is a relatively complex LDAP filter construction engine at work behind the scenes.

Because of this it is often beneficial to see just what LDAP filters are at work so you can construct your own. This module provides the means to always spit out the prior LDAP filter that was used (as well as the whole ADSI set of search parameters).

## Requirements
PowerShell 4 or greater.

## Installation

Powershell Gallery (PS 5.0, Preferred method)
`install-module PSAD`

Manual Installation
`iex (New-Object Net.WebClient).DownloadString("https://github.com/zloeber/PSAD/raw/master/Install.ps1")`

Or clone this repository to your local machine, extract, go to the .\releases\PSAD directory
and import the module to your session to test, but not install this module.

## Features

- Pure ADSI based module (so it is fast as heck)
- Ability to connect to remote or local forests with alternate credentials

## Versions

0.0.1 - Initial Release
0.0.2 - Some minor updates
0.0.3 - Lots of fixes.
0.0.4 - ???
0.0.5 - Updated the module to properly handle null attributes and included more documentation
0.0.11 - Fixed PowerShell 4 related issues with the credential parameters for most functions.

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code]
* [PowerShell Extension]

For more information on contributing go to [this link](docs/Contributing.md)

# PSAD Acknowledgements

Project Site: [https://github.com/zloeber/PSAD](https://github.com/zloeber/PSAD)

I know I'm largely creating stuff that has been done before (in many ways even more comprehensive or better than I have done here). These projects are the inspiration, and sometimes even the source code for much of this work.

**[Lazywinadmin's AdsiPS](https://github.com/lazywinadmin/AdsiPS)** -
I found this one later in my coding of this module. I plan on grabbing some stuff from this project more in the future so I may as well just list this here now.

**[DarkOperator's ADAudit](https://github.com/darkoperator/ADAudit/tree/dev)** -
This is a module in development with some great blog articles that follow the coding path taken for development. I REALLY liked the cmdlet naming convention
and some of the other tricks used in this project but found some other decisions confusing. I've taken liberally from this project.

**[PowerView (in PowerSploit)](https://github.com/PowerShellMafia/PowerSploit/tree/master/Recon)** -
I started this module by tearing this module apart. I still want to use many of the functions in this module but most of them need complete rewriting.

[ModuleBuild](https://github.com/zloeber/ModuleBuild) - A PowerShell module build framwork of my own creation.

## Other Information

**Author:** [Zachary Loeber](https://www.the-little-things.net)

**Website:** [PSAD](https://github.com/zloeber/PSAD)

**ReadTheDocs** [site](https://psad.readthedocs.io/en/latest)
