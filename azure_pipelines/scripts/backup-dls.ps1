param(
    [String]$sourceStorageAccount,
    [String]$targetStorageAccount,
    [String]$sourceFolder,
    [String]$targetFolder,
    [String]$triggerPeriod,
    [Int32]$azCopyConcurrency,
    [String]$clientID,
    [String]$clientSecret,
    [String]$tenantID
)

# Define variables
$SrcStgAccURI = "https://$sourceStorageAccount.blob.core.windows.net/"
$SrcBlobContainer = "$sourceFolder"
$SrcFullPath = "$($SrcStgAccURI)$($SrcBlobContainer)"
$DstStgAccURI = "https://$targetStorageAccount.blob.core.windows.net/"
$SPClientID = "$clientID"
$SPClientSecret = "$clientSecret"
$SPTenantID = "$tenantID"

if ($triggerPeriod -eq 'daily')
{
   $DstFileShare = "daily/$(Get-Date -format yyyyMMdd)/$sourceStorageAccount/$targetFolder"
}
else 
{
   $DstFileShare = "weekly/$(Get-Date -format yyyyMMdd)/$sourceStorageAccount/$targetFolder"
}
$DstFullPath = "$($DstStgAccURI)$($DstFileShare)"
if ($triggerPeriod -eq 'daily')
{
   $IncludeAfterDateTimeISOString = (Get-Date).AddHours(-25).ToString("o") # One hour overlap with the previous daily run
}

Write-Output "Initializing backup process"
Write-Output "Source: $sourceFolder"
Write-Output "Target: $DstFileShare"
Write-Output "Trigger period: $triggerPeriod `n"
if ($triggerPeriod -eq 'daily')
{
   Write-Output ("Trigger period: {0}" -f $IncludeAfterDateTimeISOString)
}

# Test if AzCopy.exe exists in current folder
$WantFile = "azcopy.exe"
$AzCopyExists = Test-Path $WantFile
Write-Output ("AzCopy exists: {0}" -f $AzCopyExists)

# Download AzCopy if it doesn't exist
If ($AzCopyExists -eq $False)
{
   Write-Output "AzCopy not found. Downloading..."
   
   #Download AzCopy
   Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile AzCopy.zip -UseBasicParsing

   #Expand Archive
   Write-Output "Expanding archive...`n"
   Expand-Archive ./AzCopy.zip ./AzCopy -Force

   # Copy AzCopy to current dir
   Get-ChildItem ./AzCopy/*/azcopy.exe | Copy-Item -Destination "./azcopy.exe"
   Write-Output ("Checking path")
   $AzCopyExists2 = Test-Path azcopy.exe
   Write-Output ("AzCopy exists: {0}" -f $AzCopyExists2)
}
else
{
   Write-Output "AzCopy found, skipping download.`n"
}

$env:AZCOPY_CONCURRENCY_VALUE = $azCopyConcurrency
# Login in Azure
az login --service-principal -u $SPClientID -p $SPClientSecret --tenant $SPTenantID

# Adding Public IP for this AgentPool
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
Write-Host "Adding NetworkRule for AgentPool IP: $myIp to StorageAccounts: $sourceStorageAccount and $targetStorageAccount"
$dlsStorageNetRuleAdd = az storage account network-rule add  --account-name $sourceStorageAccount --ip-address $myIP | convertFrom-Json
$bckStorageNetRuleAdd = az storage account network-rule add  --account-name $targetStorageAccount --ip-address $myIP | convertFrom-Json
# Wait some prudential time to apply the rule
Write-Host "Waiting 60 Seconds until network rules take effect..."
Start-Sleep -Seconds 60


# Run AzCopy from source blob to destination file share

Write-Host "Backing up storage account..."

$stopLoop = $false  
$retryCount = 0
Write-Host "AzCopy Login with Service Principal"
$env:AZCOPY_SPA_CLIENT_SECRET=$SPClientSecret
azcopy.exe login --service-principal --application-id $SPClientID --tenant-id $SPTenantID
Write-Host "AzCopy Login Status"
azcopy.exe login status
do {
   Write-Host "Attempt: $retryCount"
   if ($triggerPeriod -eq 'daily')
   {

      Write-Host ("./azcopy.exe copy $SrcFullPath $DstFullPath --block-blob-tier Cool --recursive --overwrite=ifsourcenewer --log-level=NONE --include-after $IncludeAfterDateTimeISOString`n")
      azcopy.exe copy $SrcFullPath $DstFullPath --block-blob-tier Cool --recursive --overwrite=ifsourcenewer --log-level=NONE --include-after $IncludeAfterDateTimeISOString
   }
   else
   {
      Write-Host ("./azcopy.exe copy $SrcFullPath $DstFullPath --block-blob-tier Cool --recursive --overwrite=ifsourcenewer --log-level=NONE`n")
      azcopy.exe copy $SrcFullPath $DstFullPath --block-blob-tier Cool --recursive --overwrite=ifsourcenewer --log-level=NONE
   }

   if ($LASTEXITCODE -ne 0) {
      $retryCount++   
   }
   elseif ($LASTEXITCODE -eq 0){
      $stopLoop = $true
   }

   if ($retryCount -eq 3) {
      $dlsResourceGroupName = $dlsStorageNetRuleAdd.resourceGroup
      Write-Host "Removing network rule from $dlsResourceGroupName : $sourceStorageAccount to delete IP: $myIP"
      $dlsStorageNetRuleRemove = az storage account network-rule remove  --account-name $sourceStorageAccount -g $dlsResourceGroupName  --ip-address $myIP
      $bckResourceGroupName = $bckStorageNetRuleAdd.resourceGroup
      Write-Host "Removing network rule from $bckResourceGroupName : $targetStorageAccount to delete IP: $myIP"
      $bckStorageNetRuleRemove = az storage account network-rule remove  --account-name $targetStorageAccount -g $bckResourceGroupName --ip-address $myIP
      
      throw "Failed after $retryCount attempts"
   }
}
While ($stopLoop -eq $false)

# As last Step, remove the network rules
$dlsResourceGroupName = $dlsStorageNetRuleAdd.resourceGroup
Write-Host "Removing network rule from $dlsResourceGroupName : $sourceStorageAccount to delete IP: $myIP"
$dlsStorageNetRuleRemove = az storage account network-rule remove  --account-name $sourceStorageAccount -g $dlsResourceGroupName  --ip-address $myIP
$bckResourceGroupName = $bckStorageNetRuleAdd.resourceGroup
Write-Host "Removing network rule from $bckResourceGroupName : $targetStorageAccount to delete IP: $myIP"
$bckStorageNetRuleRemove = az storage account network-rule remove  --account-name $targetStorageAccount -g $bckResourceGroupName --ip-address $myIP