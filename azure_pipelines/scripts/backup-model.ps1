# Backup all the models in ML Workspace
param ( # [Parameter(Mandatory, HelpMessage='Please provide the environment: demo, sit, uat, dev or prod')]
		# [ValidateSet('demo','sit','uat','dev','prod')]
		[string]$env='demo',
		[string]$resourceGroupName = 'rg-aml-da-demo',
		[string]$workspaceName = 'amlwdademo',
        [string]$storageAccountName = 'sabackupsdademo')


# Make sure the ML extension is active
# <az_ml_install>
az extension add -n ml -y
# </az_ml_install>

# ---- BLOCK SHOULD BE COMMENTED. NOT REQUIRED WHEN USING AGENT POOL DEFAULT WITH PRIVATE AKS PEERED WITH ENV VNET ----

# Adding Public IP for this AgentPool
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$mlStorage= az ml workspace list -g $resourceGroupName --query "[?name=='$workspaceName'].storage_account" | convertFrom-Json
$mlStorageName=($mlStorage.split("/"))[-1]
Write-Host "Adding NetworkRule for AgentPool IP: $myIp to StorageAccounts: $mlStorageName and $storageAccountName"
$mlStorageNetRuleAdd = az storage account network-rule add  --account-name $mlStorageName --ip-address $myIP | convertFrom-Json
$bckStorageNetRuleAdd =az storage account network-rule add  --account-name $storageAccountName --ip-address $myIP | convertFrom-Json
# Wait some prudential time to apply the rule
Write-Host "Waiting 60 Seconds until network rules take effect..."
Start-Sleep -Seconds 60
# ---- END OF BLOCK ----


$dateFormatted=Get-Date -format 'yyyyMMdd'
$outputDir='./' + $workspaceName + '-' + $dateFormatted
$containerName='aml-backup-' + $env

# Show Login user 

$loginUser = (az account show)| ConvertFrom-Json
$subscriptionName = $loginUser.name
$APP_ID = $loginUser.user.name
$TenantID = $loginUser.homeTenantId
Write-Host 'Using Subscription: ' $subscriptionName
Write-Host 'Connecting with Service Principal: ' $loginUser.user.name

# Search for all the active models
$model_name_list= az ml model list --workspace-name $workspaceName --resource-group $resourceGroupName  --query "[].{Name:name}" |convertFrom-Json

foreach ($model_name in $model_name_list.name) { 
    # Write-Output 'Model Name: $model_name'
    # get all the model versions
    $model_version_list=az ml model list --workspace-name $workspaceName --resource-group $resourceGroupName --name $model_name --query "[].{Name:name, Version:version}" |convertFrom-Json
    foreach ($model_version in $model_version_list.Version) { 
        $downloadDir=$outputDir + '/' + $model_name  + '-version-' + $model_version
        Write-Output "Model Name: $model_name with Version: $model_version will be backup at: $downloadDir"
        az ml model download --name $model_name --version $model_version  --download-path $downloadDir --resource-group $resourceGroupName --workspace-name $workspaceName
    }
}
# Once all the models were exported, proceed to compress the dir 
$zipFile=$outputDir + '.zip'
Compress-Archive -Force $outputDir $zipFile


# Verify that Containter exists. 
$existStorage = az storage account check-name --name $storageAccountName --query reason --subscription $subscriptionName
if ($existStorage) {
    Write-Host " Storage Account $storageAccountName already exists"
    # Get the key1 for the Storage Account and SasToken active for 30 Minutes
    $expireDate=(Get-Date).AddMinutes(30).tostring('yyyy-MM-ddTHH:mmZ')
    $accountKey1=az storage account keys list --account-name $storageAccountName --query "[?keyName=='key1'].value" | ConvertFrom-Json
    $accountSAS=az storage account generate-sas --account-name $storageAccountName --account-key $accountKey1 --permissions cdlrwa --services b --resource-types sco --expiry $expireDate -o tsv

} else {
    Write-Host "Storage Account $storageAccountName does not exists. Aborting script"
    exit
}
$containerVerify = az storage container list --account-name $storageAccountName --auth-mode login --query "[?name=='$containerName']" | ConvertFrom-Json	
if ($containerVerify.Length -eq 0) { 
     Write-Host "Creating Container $containerName in Storage Account $storageAccountName"
     az storage container create --account-name $storageAccountName --auth-mode login -g $resourceGroupName --name $containerName
 } else { 
    Write-Host "Container $containerName in Storage Account $storageAccountName already exists" 
}
Write-Host "Uploading File $zipFile to storage account: $storageAccountName in Container: $containerName"
az storage blob upload --account-name $storageAccountName --auth-mode login `
    --container-name $containerName `
    --name $zipFile `
    --file $zipFile `
    --overwrite true `
    --only-show-errors

Write-Host "Listing Files from storage account: $storageAccountName - Container: $containerName"
az storage blob list `
    --account-name $storageAccountName --auth-mode login `
    --container-name $containerName `
    --output table 


# ---- BLOCK SHOULD BE COMMENTED. NOT REQUIRED WHEN USING AGENT POOL DEFAULT WITH PRIVATE AKS PEERED WITH ENV VNET ----

# As last Step, remove the network rules
Write-Host "Removing network rule from $resourceGroupName : $mlStorageName to delete IP: $myIP"
$mlStorageNetRuleRemove = az storage account network-rule remove  --account-name $mlStorageName -g $resourceGroupName  --ip-address $myIP
$bckResourceGroupName = $bckStorageNetRuleAdd.resourceGroup
Write-Host "Removing network rule from $bckResourceGroupName : $storageAccountName to delete IP: $myIP"
$bckStorageNetRuleRemove = az storage account network-rule remove  --account-name $storageAccountName -g $bckResourceGroupName --ip-address $myIP

 # ---- END OF BLOCK ----