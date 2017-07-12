# PSAD

Advanced ADSI PowerShell Module

## Description

Advanced ADSI PowerShell Module

## Introduction

Yet another AD PowerShell module that you may want to try out.

## Requirements
PowerShell 3 should be all that is needed.

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

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code]
* [PowerShell Extension]

For more information on contributing go to [this link](docs/Contributing.md)

## Other Information

**Author:** [Zachary Loeber](https://www.the-little-things.net)
**Website:** https://github.com/zloeber/PSAD
**ReadTheDocs** [site](psad.readthedocs.io/en/latest/)
