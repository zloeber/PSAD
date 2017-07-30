# Discovery

This module was built with Active Directory discovery in mind. Most of the base functions can be used to pull all kinds of fun information from AD without much extra effort but I've gone ahead and included additional wrapper functions for finding out more about OCS/Lync/S4b, SCCM, DFS, DFSR, FRS, and Exchange.


## Exchange Servers

Exchange server information in the config partition can be queried with a single command:

```
get-dsexchangeserver
```

## Exchange Federations

Exchange federation infomation is stored in the configuration partition and can be easily queried with:

```
get-dsexchangefederation
```

## Different Schema Versions
Exchange, Lync, and AD can have different update versions installed. Getting this information is pretty easy:

```
Get-DSExchangeSchemaVersion
Get-DSOCSSchemaVersion
Get-DSADSchemaVersion
```