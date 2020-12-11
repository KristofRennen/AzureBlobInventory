# AzureBlobInventory

The purpose of this repository is to bundle scripts that will allow an administrator of an Azure Blob Storage account to generate a full inventory of all objects existing in an account.

## Pre-requisites

The script leverages the Azure PowerShell modules, which can be installed via the regular route
https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.1.0

In order to leverage this script, you need authenticated and authorized access to the Azure Subscription.
Through a full AAD based authentication, the user executing the script needs access to the Storage Account being used for inventory.

## Create-BlobInventory.ps1

The script has 5 mandatory parameters that can be used to create a segmented inventory of larger accounts.
Using the storage account key parameter allows to overrule the AAD authentication.

```powershell
param
(
    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $SubscriptionId,

    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $ResourceGroup,

    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $StorageAccount,

    [Parameter(Mandatory = $False, valueFromPipeline=$true)]
    [String] $StorageAccountKey,

    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $Container,
    
    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $Prefix,

    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $OutputPath
)
```

It leverages the Get-AzStorageBlob PowerShell command to list all objects in the given account:
Get-AzStorageBlob -Context $StorageAccountContext -Container $Container -Prefix $Prefix -MaxCount $MaxResults -ContinuationToken $ContinuationToken

The script will loop all objects in the account as a flat listing and output them to a file per 5000 entries.
The resulting file will be stored in "$OutputPath\Account='$($StorageAccount)'__Container='$($Container)'__Prefix='$($Prefix)'.dat"