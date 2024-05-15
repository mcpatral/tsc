# For Sandbox environment copying only. Not used in pipelines
param (
  [string]$VaultName,
  [string]$VaultResourceGroup,
  [string]$VaultSubscriptionId = "",
  [string]$NewVaultName,
  [string]$NewVaultResourceGroup,
  [string]$NewVaultSubscriptionId = ""
)

$ErrorActionPreference = "Stop"

If ($VaultSubscriptionId -Eq "") {
  $VaultSubscriptionId = az account show --query "id" --output tsv
  Write-Output "Source Vault subscription parameter is not set... Using default subscription - $VaultSubscriptionId"
}

If ($NewVaultSubscriptionId -Eq "") {
  $NewVaultSubscriptionId = az account show --query "id" --output tsv
  Write-Output "Target Vault subscription parameter is not set... Using default subscription - $NewVaultSubscriptionId"
}

Write-Output "Getting public IP address of workstation and KV information..."
$IpAddress = (Invoke-WebRequest -Uri https://ifconfig.me).Content

$VaultPublicNetworkAccess = az keyvault show --name $VaultName --resource-group $VaultResourceGroup --subscription $VaultSubscriptionId `
  --query "properties.publicNetworkAccess" --output tsv
$VaultNetworkRuleList = az keyvault network-rule list --name $VaultName --resource-group $VaultResourceGroup --subscription $VaultSubscriptionId `
  --query "ipRules[].value" --output tsv
$VaultNetworkRuleExist = $False

If ( $Null -Ne $VaultNetworkRuleList ) {
  $VaultNetworkRuleExist = $VaultNetworkRuleList.Contains($IpAddress)
}

If ($VaultPublicNetworkAccess.Equals("Disabled")) {
  Write-Output "Enabling public network access for KV..."
  az keyvault update --name $VaultName --resource-group $VaultResourceGroup --subscription $VaultSubscriptionId `
    --public-network-access "Enabled" --default-action "Deny"
}

If ( -Not $VaultNetworkRuleExist ) {
  Write-Output "Enabling public network access for KV..."
  az keyvault network-rule add --name $VaultName --resource-group $VaultResourceGroup --subscription $VaultSubscriptionId --ip-address $IpAddress
}

$NewVaultPublicNetworkAccess = az keyvault show --name $NewVaultName --resource-group $NewVaultResourceGroup --subscription $NewVaultSubscriptionId `
  --query "properties.publicNetworkAccess" --output tsv
$NewVaultNetworkRuleList = az keyvault network-rule list --name $NewVaultName --resource-group $NewVaultResourceGroup --subscription $NewVaultSubscriptionId `
  --query "ipRules[].value" --output tsv
$NewVaultNetworkRuleExist = $False

If ( $Null -Ne $NewVaultNetworkRuleList ) {
  $NewVaultNetworkRuleExist = $NewVaultNetworkRuleList.Contains($IpAddress)
}

If ($NewVaultPublicNetworkAccess.Equals("Disabled")) {
  Write-Output "Enabling public network access for KV..."
  az keyvault update --name $NewVaultName --resource-group $NewVaultResourceGroup --subscription $NewVaultSubscriptionId `
    --public-network-access "Enabled" --default-action "Deny"
}

If ( -Not $NewVaultNetworkRuleExist ) {
  Write-Output "Enabling public network access for KV..."
  az keyvault network-rule add --name $NewVaultName --resource-group $NewVaultResourceGroup --subscription $NewVaultSubscriptionId --ip-address $IpAddress
}

If ($VaultPublicNetworkAccess.Equals("Disabled") -Or $NewVaultPublicNetworkAccess.Equals("Disabled") -Or ( -Not $VaultNetworkRuleExist ) -Or ( -Not $NewVaultNetworkRuleExist )) {
  Write-Output "Waiting for 60 seconds for changes to be applied..."
  Start-Sleep -Seconds 60
}

Write-Output "Getting secrets list from old KV..."
az keyvault secret list --vault-name $VaultName --subscription $VaultSubscriptionId --query "[].name" --output tsv > secrets

$ErrorActionPreference = "Continue"

Write-Output "Populating new KV with secrets..."
Get-Content ./secrets | ForEach-Object {
  $SecretValue = az keyvault secret show -n $_ --vault-name $VaultName --subscription $VaultSubscriptionId --query "value" --output tsv
  az keyvault secret set --name $_ --vault-name $NewVaultName --subscription $NewVaultSubscriptionId --value $SecretValue
  If ( -Not $? ) {
    Write-Warning "Error appeared during write to KV... Retrying write using separate file..."
    Set-Content -Path ./$_ -Value "$SecretValue"
    az keyvault secret set --name $_ --vault-name $NewVaultName --file ./$_ --subscription $NewVaultSubscriptionId
    if ( -Not $? ) {
      Write-Warning "Failed to write secret into KV... Saving secret name into separate failed-secrets file and proceeding futher..."
      Add-Content -Path ./failed-secrets -Value "$_"
    }
  }
}

Write-Output "Disabling public network access and removing temporary files..."
az keyvault update --name $VaultName --resource-group $VaultResourceGroup --subscription $VaultSubscriptionId `
  --public-network-access "Disabled" --default-action "Deny"
az keyvault update --name $NewVaultName --resource-group $NewVaultResourceGroup --subscription $NewVaultSubscriptionId `
  --public-network-access "Disabled" --default-action "Deny"
Remove-Item ./secrets
