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

if ($StorageAccountKey -eq $Null -or $StorageAccountKey -eq "") 
{
    # Connect to the Azure Subscritpion
    Connect-AzAccount -Subscription $SubscriptionId

    # Connect to the Storage Namespace
    $StorageAccountKey = ((Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount) | Where-Object {$_.KeyName -eq "key1"}).Value
}

# Create storage auth context
$StorageAccountContext = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey

# Loop all matching objects for inventorization
$MaxResults = 5000
$TotalResults = 0
$ContinuationToken = $Null

# Inventorize
$InventoryFile = "$OutputPath\Account='$($StorageAccount)'__Container='$($Container)'__Prefix='$($Prefix)'.dat"

Do 
{
    $Blobs = Get-AzStorageBlob -Context $StorageAccountContext -Container $Container -Prefix $Prefix -MaxCount $MaxResults -ContinuationToken $ContinuationToken
        
    $TotalResults += $Blobs.Count

    if ($Blobs.Length -le 0) { Break; }

    $ContinuationToken = $Blobs[$Blobs.Count - 1].ContinuationToken;

    $ItemBuilder = [System.Text.StringBuilder]::new()
    $Blobs | ForEach-Object { [void]$ItemBuilder.AppendLine("$($_.Name)") } 
    Add-Content $InventoryFile $ItemBuilder.ToString()
     
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')   Inventorized $TotalResults objects so far, still working" -ForegroundColor Cyan
}
While ($ContinuationToken -ne $Null)

Write-Host -Message "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')   Inventorized $TotalResults objects matching $StorageAccount/$Container/$Prefix" -ForegroundColor Cyan