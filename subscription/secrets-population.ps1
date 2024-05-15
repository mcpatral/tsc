param (
  [string]$VaultName,
  [string]$ResourceGroupName,
  [string]$PathToSecretFile,
  [string]$SubscriptionId = ""
)

$ErrorActionPreference = "Stop"

If ($SubscriptionId -Eq "") {
  $SubscriptionId = az account show --query "id" --output tsv
  Write-Output "Subscription parameter is not set... Using default subscription - $SubscriptionId"
}

Write-Output "Getting public IP address of workstation and KV information..."
$IpAddress = (Invoke-WebRequest -Uri https://ifconfig.me).Content

$PublicNetworkAccess = az keyvault show --name $VaultName --resource-group $ResourceGroupName --subscription $SubscriptionId `
  --query "properties.publicNetworkAccess" --output tsv
$NetworkRuleList = az keyvault network-rule list --name $VaultName --resource-group $ResourceGroupName --subscription $SubscriptionId `
  --query "ipRules[].value" --output tsv
$NetworkRuleExist = $False

If ( $Null -Ne $NetworkRuleList ) {
  $NetworkRuleExist = $NetworkRuleList.Contains($IpAddress)
}

If ($PublicNetworkAccess.Equals("Disabled")) {
  Write-Output "Enabling public network access for KV..."
  az keyvault update --name $VaultName --resource-group $ResourceGroupName --subscription $SubscriptionId `
    --public-network-access "Enabled" --default-action "Deny"
}

If ( -Not $NetworkRuleExist ) {
  Write-Output "Enabling public network access for KV..."
  az keyvault network-rule add --name $VaultName --resource-group $ResourceGroupName --subscription $SubscriptionId --ip-address $IpAddress
}

If ($PublicNetworkAccess.Equals("Disabled") -Or ( -Not $NetworkRuleExist )) {
  Write-Output "Waiting for 60 seconds for changes to be applied..."
  Start-Sleep -Seconds 60
}

$ErrorActionPreference = "Continue"

Write-Output "Populating KV with secrets..."
Get-Content $PathToSecretFile | ForEach-Object {
  $SecretName = ($_ -split('=', 2)).Trim()[0]
  $SecretValue = ($_ -split('=', 2)).Trim()[1]
  az keyvault secret set --name $SecretName --vault-name $VaultName --subscription $SubscriptionId --value $SecretValue
  If ( -Not $? ) {
    Write-Warning "Error appeared during write to KV... Retrying write using separate file..."
    Set-Content -Path ./$SecretName -Value "$SecretValue"
    az keyvault secret set --name $SecretName --vault-name $VaultName --subscription $SubscriptionId --file ./$SecretName
    if ( -Not $? ) {
      Write-Warning "Failed to write secret into KV... Saving secret name into separate failed-secrets file and proceeding futher..."
      Add-Content -Path ./failed-secrets -Value "$SecretName"
    }
  }
}

az keyvault update --name $VaultName --resource-group $ResourceGroupName --subscription $SubscriptionId `
  --public-network-access "Disabled" --default-action "Deny"
