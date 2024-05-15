param (
  [string]$SubscriptionType,
  [string]$SubscriptionId = "",
  [string]$DevopsGroupObjectId = "",
  [string]$DeveloperGroupObjectId = "",
  [string]$QaGroupObjectId = "",
  [string]$DataScientistGroupObjectId = "",
  [string]$SASupportGroupObjectId = "",
  [string]$OwnerGroupObjectId = ""
)

$ErrorActionPreference = "Stop"

If ($SubscriptionId -Eq "") {
  $SubscriptionId = az account show --query "id" --output tsv
  Write-Output "Subscription parameter is not set... Using default subscription - $SubscriptionId"
}

Write-Output "Configuring permissions for subscription..."
Get-Content ./rbac/$SubscriptionType/devops-roles | ForEach-Object {
  az role assignment create --assignee-object-id $DevopsGroupObjectId --role $_ --scope "/subscriptions/$SubscriptionId" --assignee-principal-type Group
}

Get-Content ./rbac/$SubscriptionType/developer-roles | ForEach-Object {
  az role assignment create --assignee-object-id $DeveloperGroupObjectId --role $_ --scope "/subscriptions/$SubscriptionId" --assignee-principal-type Group
}

Get-Content ./rbac/$SubscriptionType/qa-roles | ForEach-Object {
  az role assignment create --assignee-object-id $QaGroupObjectId --role $_ --scope "/subscriptions/$SubscriptionId" --assignee-principal-type Group
}

Get-Content ./rbac/$SubscriptionType/datascientist-roles | ForEach-Object {
  az role assignment create --assignee-object-id $DataScientistGroupObjectId --role $_ --scope "/subscriptions/$SubscriptionId" --assignee-principal-type Group
}

Get-Content ./rbac/$SubscriptionType/sasupport-roles | ForEach-Object {
  az role assignment create --assignee-object-id $SASupportGroupObjectId --role $_ --scope "/subscriptions/$SubscriptionId" --assignee-principal-type Group
}

Get-Content ./rbac/$SubscriptionType/owner-roles | ForEach-Object {
  az role assignment create --assignee-object-id $OwnerGroupObjectId --role $_ --scope "/subscriptions/$SubscriptionId" --assignee-principal-type Group
}
