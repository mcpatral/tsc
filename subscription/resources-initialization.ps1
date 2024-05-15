param (
  [string]$SubscriptionId = "",
  [string]$EnvironmentName,
  [string]$Region = "WestEurope",
  [string]$RegionShort = "weu",
  [switch]$CreateTestKv = $False
)

$ErrorActionPreference = "Stop"

If ($SubscriptionId -Eq "") {
  $SubscriptionId = az account show --query "id" --output tsv
  Write-Output "Subscription parameter is not set... Using default subscription - $SubscriptionId"
}

Write-Output "Getting public IP address of workstation and KV information..."
$IpAddress = (Invoke-WebRequest -Uri https://ifconfig.me).Content
Write-Output "Agent IP - $IpAddress"

Write-Output "Checking existance of resources..."
$CentralRgList = az group list --subscription $SubscriptionId --query "[].name" --output tsv
$StateRgList = az group list --subscription $SubscriptionId --query "[].name" --output tsv

$CentralRgCreated = $False
$StateRgCreated = $False

If ( $Null -Ne $CentralRgList ) {
  $CentralRgCreated = $CentralRgList.Contains("rg-$EnvironmentName-da-$RegionShort-central-manual")
}

If ( $Null -Ne $StateRgList ) {
  $StateRgCreated = $StateRgList.Contains("rg-$EnvironmentName-da-$RegionShort-state")
}

$TestKvCreated = $False
$MasterKvCreated = $False
$StateSaCreated = $False

If ($CentralRgCreated -And $CreateTestKv) {
  $TestKvList = az keyvault list --resource-group "rg-$EnvironmentName-da-$RegionShort-central-manual" --subscription $SubscriptionId `
    --query "[].name" --output tsv

  If ( $Null -Ne $TestKvList ) {
    $TestKvCreated = $TestKvList.Contains("kv-$EnvironmentName-da-$RegionShort-test")
  }
}

If ($StateRgCreated) {
  $MasterKvList = az keyvault list --resource-group "rg-$EnvironmentName-da-$RegionShort-state" --subscription $SubscriptionId `
    --query "[].name" --output tsv
  
  If ( $Null -Ne $MasterKvList ) {
    $MasterKvCreated = $MasterKvList.Contains("kv-$EnvironmentName-da-$RegionShort-master")
  }

  $StateSaList = az storage account list --resource-group "rg-$EnvironmentName-da-$RegionShort-state" --subscription $SubscriptionId `
    --query "[].name" --output tsv
  
  If ( $Null -Ne $StateSaList ) {
    $StateSaCreated = $StateSaList.Contains("sa${EnvironmentName}da${RegionShort}tfstate")
  }
}

If ( (-Not $CentralRgCreated) -And $CreateTestKv ) {
  Write-Output "Creating Central RG..."
  az group create --name "rg-$EnvironmentName-da-$RegionShort-central-manual" --location $Region --subscription $SubscriptionId
}

If ($CreateTestKv) {
  If ( -Not $TestKvCreated ) {
    Write-Output "Checking whether Test KV was removed previously..."
    $TestKvList = az keyvault list-deleted --subscription $SubscriptionId `
    --query "[].name" --output tsv
    $TestKvDeleted = $False
    
    If ( $Null -Ne $TestKvList ) {
      $TestKvDeleted = $TestKvList.Contains("kv-$EnvironmentName-da-$RegionShort-test")
    }
  
    If ($TestKvDeleted) {
      Write-Output "Recovering Test KV..."
      az keyvault recover --name "kv-$EnvironmentName-da-$RegionShort-test" --resource-group "rg-$EnvironmentName-da-$RegionShort-central-manual" `
        --subscription $SubscriptionId --location $Region
    } Else {
      Write-Output "Creating Test KV..."
      az keyvault create --name "kv-$EnvironmentName-da-$RegionShort-test" --resource-group "rg-$EnvironmentName-da-$RegionShort-central-manual" `
        --subscription $SubscriptionId --location $Region --public-network-access Disabled --default-action Deny --enable-rbac-authorization true
    }
  }
}

If ( -Not $StateRgCreated ) {
  Write-Output "Creating State RG..."
  az group create --name "rg-$EnvironmentName-da-$RegionShort-state" --location $Region --subscription $SubscriptionId
}

If ( -Not $MasterKvCreated ) {
  $MasterKvList = az keyvault list-deleted --subscription $SubscriptionId `
    --query "[].name" --output tsv
  $MasterKvDeleted = $False
  
  If ( $Null -Ne $MasterKvList ) {
    $MasterKvDeleted = $MasterKvList.Contains("kv-$EnvironmentName-da-$RegionShort-master")      
  }
  
  If ($MasterKvDeleted) {
    Write-Output "Recovering Master KV..."
    az keyvault recover --name "kv-$EnvironmentName-da-$RegionShort-master" --resource-group "rg-$EnvironmentName-da-$RegionShort-state" `
      --subscription $SubscriptionId --location $Region
  } Else {
    Write-Output "Creating Master KV..."
    az keyvault create --name "kv-$EnvironmentName-da-$RegionShort-master" --resource-group "rg-$EnvironmentName-da-$RegionShort-state" `
      --subscription $SubscriptionId --location $Region --public-network-access Disabled --default-action Deny --enable-rbac-authorization true
  }
}

If ( -Not $StateSaCreated ) {
  Write-Output "Creating State SA..."
  az storage account create --name "sa${EnvironmentName}da${RegionShort}tfstate" --resource-group "rg-$EnvironmentName-da-$RegionShort-state" `
    --subscription $SubscriptionId --public-network-access Disabled --default-action Deny
}

Write-Output "Checking SA Network rules and enabling public access..."
$SaNetworkRuleList = (az storage account update --name "sa${EnvironmentName}da${RegionShort}tfstate" --resource-group "rg-$EnvironmentName-da-$RegionShort-state" `
  --subscription $SubscriptionId --public-network-access Enabled --default-action Deny --query "networkRuleSet.ipRules[].ipAddressOrRange" --output tsv)
$SaNetworkRuleExist = $False

If ($Null -Ne $SaNetworkRuleList) {
  $SaNetworkRuleExist = $SaNetworkRuleList.Contains($IpAddress)
}

If ( -Not $SaNetworkRuleExist ) {
  Write-Output "Adding workstation IP to SA network rules..."
  az storage account network-rule add --account-name "sa${EnvironmentName}da${RegionShort}tfstate" --resource-group "rg-$EnvironmentName-da-$RegionShort-state" `
    --subscription $SubscriptionId --ip-address $IpAddress
}

Write-Output "Waiting for network rules to be applied (60 seconds)..."
Start-Sleep -Seconds 60

Write-Output "Creating SA container for Terraform states..."
az storage container create --name "${EnvironmentName}tfstate" --subscription $SubscriptionId --auth-mode login `
  --account-name "sa${EnvironmentName}da${RegionShort}tfstate"

az storage account update --name "sa${EnvironmentName}da${RegionShort}tfstate" --resource-group "rg-$EnvironmentName-da-$RegionShort-state" `
  --subscription $SubscriptionId --public-network-access Disabled --default-action Deny
