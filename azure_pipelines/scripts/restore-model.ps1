# Restore all models or just selected ones in ML Workspace
param ( # [Parameter(Mandatory, HelpMessage='Please provide the environment: demo, sit, uat, dev or prod')]
		# [ValidateSet('demo','sit','uat','dev','prod')]
		[string]$env='demo',
		[string]$resourceGroupName = 'rg-aml-da-demo',
		[string]$workspaceName = 'amlwdademo',
        [string]$storageAccountName = 'sabackupsdademo',
        [string]$sourceFile='Newest',
        [string[]]$selectedModelList='All',
        [switch]$restoreAsNewVersion)

# Make sure the ML extension is active
# <az_ml_install>
az extension add -n ml -y
# </az_ml_install>

# ---- BLOCK SHOULD BE COMMENTED. NOT REQUIRED WHEN USING AGENT POOL DEFAULT WITH PRIVATE AKS PEERED WITH ENV VNET ----

# Adding Public IP for this AgentPool
$myIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$mlStorage= az ml workspace list -g $resourceGroupName --query "[?name=='$workspaceName'].storage_account" | convertFrom-Json
$mlStorageName=($mlStorage.split("/"))[-1]
Write-Host "Adding NetworkRule for AgentPool IP: $myIP to StorageAccounts: $mlStorageName and $storageAccountName"
$mlStorageNetRuleAdd = az storage account network-rule add  --account-name $mlStorageName --ip-address $myIP | convertFrom-Json
$bckStorageNetRuleAdd =az storage account network-rule add  --account-name $storageAccountName --ip-address $myIP | convertFrom-Json
Write-Host "Waiting 60 Seconds until network rules take effect..."
# Wait some prudential time to apply the rule
Start-Sleep -Seconds 60

# ---- END OF BLOCK ----

# Getting zip file to restore from backup repository
$containerName='aml-backup-' + $env
Write-Host "Getting zip file to restore from backup repository: $storageAccountName - $containerName."
if ($sourceFile -eq 'Newest') {
    [string] $fileToDownload=az storage blob list --account-name $storageAccountName --auth-mode login --container-name $containerName `
    --query "[].{Name:name, LastModified:properties.lastModified} | max_by(@, &LastModified) | Name" | ConvertFrom-Json
    if ($fileToDownload.Length -eq 0) {
        Write-Host "Could not get any backup file on: $storageAccountName - $containerName. Aborting restore..."
        exit
    }
} else {
    [string] $fileToDownload=az storage blob list --account-name $storageAccountName --auth-mode login --container-name $containerName `
    --query "[?name=='$sourceFile'].name" | ConvertFrom-Json
    if ($fileToDownload.Length -eq 0) {
        throw "File: $sourceFile does not exists. Aborting restore..."
    }
}
# Downloading File
Write-Host "Downloading File $fileToDownload from storage account: $storageAccountName - Container: $containerName to Local"
$fileBckDownload = az storage blob download --account-name $storageAccountName --auth-mode login `
                    --container-name $containerName `
                    --name $fileToDownload `
                    --file $fileToDownload `
                    --overwrite true `
                    --only-show-errors
# Uncompress the file
Expand-Archive -Path $fileToDownload -DestinationPath "." -Force

# Get models:version on backup 
$recoverDir=$fileToDownload.split('.')[0]
$models=Get-ChildItem $recoverDir
# storing info as System.Collections.Hashtable
$modelsOnBackupList=@()
Write-Host "`r`n Listing Backup content in $fileToDownload"
foreach ($dir in $models.Name) {
    $model= $dir -Split "-version-"
    $modelName=$model[0]
    $modelVersion=$model[1]
    $path1=(Get-ChildItem $recoverDir/$dir/*).Name
    $path2=(Get-ChildItem $recoverDir/$dir/*/*).Name
    $modelPath="$recoverDir/$dir/$path1/$path2"
    Write-Host "dir: $dir Model: $modelName with Version: $modelVersion Path: $modelPath"
    $modelsOnBackupList+=(@{model=($dir);path=($modelPath);name=($modelName);version=($modelVersion)})
}
# $modelsOnBackupList

# Select model to restore
Write-Host "`r`n Select model to restore... $selectedModelList"
$selectedFromBackupList = @()
if ($selectedModelList -eq 'All') {
    $selectedFromBackupList = $modelsOnBackupList
    Write-Host "Including All Models on Backup"
} else {
    # Validate that any model name received as parameter, is included into the backup file
	foreach ($selectedModel in $selectedModelList) {
		if ($modelsOnBackupList.model -NotContains $selectedModel) {
			Write-Host "invalid Model name: $selectedModel Excluded from restore"
        } else {
            Write-Host "Adding $selectedModel To the Model List to Restore"
            $selectedFromBackupList += $modelsOnBackupList | ?{ $selectedModel  -Contains $_.model}
		} 
	}
}
# 
Write-Host "`r`n List of selectedFromBackupList"
$selectedFromBackupList

# Obtain the Model List on target Workspace 
Write-Host "Obtaining the Model List on target Workspace: $workspaceName"
$modelNameList= az ml model list --workspace-name $workspaceName --resource-group $resourceGroupName  --query "[].{Name:name}" |convertFrom-Json
$modelsOnTargetList= @()
foreach ($modelName in $modelNameList.name) { 
    $modelVersionList=az ml model list --workspace-name $workspaceName --resource-group $resourceGroupName --name $modelName --query "[].{Name:name, Version:version}" |convertFrom-Json
    foreach ($modelVersion in $modelVersionList.Version) { 
        $modelsOnTargetList+=$modelName  + '-version-' + $modelVersion
    }
}
# $modelsOnTargetList

# In the case the Model already exists on Target, it will created as new version, but only if the $restoreAsNewVersion switch is True
$modelsToRestoreWithNewVersion = @()
$modelsToRestoreWithNewVersion += $selectedFromBackupList | ?{$modelsOnTargetList -Contains $_.model}
if ($restoreAsNewVersion){
    if ($modelsToRestoreWithNewVersion.Length -gt 0) {
        $modelsToRestoreWithNewVersion.GetEnumerator()| ForEach-Object  {
            Write-Host "Restoring Model: $($_.model) with name: $($_.name) and version: $($_.version) as NEW VERSION"
            $createdModel= az ml model create --name $($_.name)  `
                --resource-group $resourceGroupName --workspace-name $workspaceName `
                --path $($_.path) | ConvertFrom-Json
            Write-Host "...Model: $($createdModel.name) Restored with Version: $($createdModel.version)"
        }
    }
} else {
    Write-Host "`r`n The following $($modelsToRestoreWithNewVersion.Length) Models Will not be restored since -restoreAsNewVersion switch is not set"
    $modelsToRestoreWithNewVersion.model
}

# Models to restore
$modelsToRestore = @()
$modelsToRestore += $selectedFromBackupList | ?{$modelsOnTargetList -NotContains $_.model}
if($modelsToRestore.Length -gt 0) {
    $modelsToRestore.GetEnumerator()| ForEach-Object  {
        Write-Host "Restoring Model: $($_.model) with name: $($_.name) and version: $($_.version)"
        $createdModel = az ml model create --name $($_.name) --version $($_.version) `
                        --resource-group $resourceGroupName --workspace-name $workspaceName `
                        --path $($_.path) | ConvertFrom-Json
        Write-Host "...Model: $($createdModel.name) Restored with Version: $($createdModel.version)"
    }
}

# ---- BLOCK SHOULD BE COMMENTED. NOT REQUIRED WHEN USING AGENT POOL DEFAULT WITH PRIVATE AKS PEERED WITH ENV VNET ----

# As last Step, remove the network rules
Write-Host "`r`n Removing network rule from $resourceGroupName : $mlStorageName to delete IP: $myIP"
$mlStorageNetRuleRemove = az storage account network-rule remove  --account-name $mlStorageName -g $resourceGroupName  --ip-address $myIP
$bckResourceGroupName = $bckStorageNetRuleAdd.resourceGroup
Write-Host "Removing network rule from $bckResourceGroupName : $storageAccountName to delete IP: $myIP"
$bckStorageNetRuleRemove = az storage account network-rule remove  --account-name $storageAccountName -g $bckResourceGroupName --ip-address $myIP

# ---- END OF BLOCK ----