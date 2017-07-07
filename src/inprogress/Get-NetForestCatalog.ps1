function Get-NetForestCatalog {
<#
.SYNOPSIS
Return all global catalogs for a given forest.

.DESCRIPTION
Return all global catalogs for a given forest.

.PARAMETER Forest

The forest name to query domain for.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

PS C:\> Get-NetForestCatalog
#>
    
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest,

        [Management.Automation.PSCredential]
        $Credential
    )

    $ForestObject = Get-NetForest -Forest $Forest -Credential $Credential

    if($ForestObject) {
        $ForestObject.FindAllGlobalCatalogs()
    }
}