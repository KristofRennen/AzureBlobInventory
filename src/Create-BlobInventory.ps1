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
    
    [Parameter(Mandatory = $False, valueFromPipeline=$true)]
    [String] $Prefix,

    [Parameter(Mandatory = $True, valueFromPipeline=$true)]
    [String] $OutputFile
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
$TotalSize = 0
$ContinuationToken = $Null

Write-Host ""
Write-Host "Inventory creation started at $(Get-Date)" -ForegroundColor Yellow
Write-Host "`t > Storage Account: $($StorageAccount)" -ForegroundColor Yellow
Write-Host "`t > Container: $($Container)" -ForegroundColor Yellow
Write-Host "`t > Prefix: $($Prefix)" -ForegroundColor Yellow
Write-Host ""
Write-Host "`t > Output: $($OutputFile)" -ForegroundColor Yellow
Write-Host ""

$Stopwatch =  [system.diagnostics.stopwatch]::StartNew()

Do 
{
    $TotalProgressedSecondsAtIterationStart = $Stopwatch.Elapsed.TotalSeconds

    if ($Prefix -eq $null -or $Prefix -eq "") 
    {
        $Blobs = Get-AzStorageBlob -Context $StorageAccountContext -Container $Container -MaxCount $MaxResults -ContinuationToken $ContinuationToken
    }
    else
    {
        $Blobs = Get-AzStorageBlob -Context $StorageAccountContext -Container $Container -Prefix $Prefix -MaxCount $MaxResults -ContinuationToken $ContinuationToken
    }
        
    $TotalResults += $Blobs.Count

    if ($Blobs.Length -le 0) { Break; }

    $ContinuationToken = $Blobs[$Blobs.Count - 1].ContinuationToken;

    $ItemBuilder = [System.Text.StringBuilder]::new()
    
    $Blobs | ForEach-Object { 
        
        [void]$ItemBuilder.AppendLine("$($_.Name),$($_.Length)") 
        $TotalSize += $_.Length
    } 
    
    Add-Content $OutputFile $ItemBuilder.ToString().Trim()

    $TotalProgressedSecondsAtIterationEnd = $Stopwatch.Elapsed.TotalSeconds
     
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss') `t Inventorized $TotalResults objects (Processing) `t`t [Elapsed $($Stopwatch.Elapsed), $([math]::Floor($Blobs.Count / ($TotalProgressedSecondsAtIterationEnd - $TotalProgressedSecondsAtIterationStart))) OPS]" -ForegroundColor Cyan
}
While ($ContinuationToken -ne $Null)

$Stopwatch.Stop()

Write-Host ""
Write-Host "Inventory creation completed at $(Get-Date)" -ForegroundColor Yellow
Write-Host "`t > Storage Account: $($StorageAccount)" -ForegroundColor Yellow
Write-Host "`t > Container: $($Container)" -ForegroundColor Yellow
Write-Host "`t > Prefix: $($Prefix)" -ForegroundColor Yellow
Write-Host ""
Write-Host "`t > Output: $($OutputFile)" -ForegroundColor Yellow
Write-Host ""
Write-Host "`t > Total objects processed: $($TotalResults)" -ForegroundColor Yellow
Write-Host "`t > Total bytes: $($TotalSize)" -ForegroundColor Yellow
Write-Host ""
Write-Host "`t > Elapsed: $($Stopwatch.Elapsed)" -ForegroundColor Yellow
Write-Host "`t > Requests per second: $([math]::Floor($TotalResults / $Stopwatch.Elapsed.TotalSeconds))" -ForegroundColor Yellow