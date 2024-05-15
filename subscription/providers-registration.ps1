param (
  [string]$SubscriptionId = ""
)

If ($SubscriptionId -Eq "") {
  $SubscriptionId = az account show --query "id" --output tsv
  Write-Output "Subscription parameter is not set... Using default subscription - $SubscriptionId"
}

$ErrorActionPreference = "Continue"

Write-Output "Activating providers and features for subscription..."
Get-Content ./providers | ForEach-Object {
  Write-Output "Activating $_"
  If ( $_ -Contains "/" ) {
    $Namespace = $_.Split("/")[0]
    $Provider = $_.Split("/")[1]
    az feature register -n $Provider --namespace $Namespace --wait --subscription $SubscriptionId
    If ( -Not $? ) {
      Write-Warning "Failed to register $Provider provider in $Namespace namespace... Retrying one more time..."
      az feature register -n $Provider --namespace $Namespace --wait --subscription $SubscriptionId
    }
  } Else {
    az provider register -n $_ --wait --subscription $SubscriptionId
    If ( -Not $? ) {
      Write-Warning "Failed to register $_ provider... Retrying one more time..."
      az provider register -n $_ --wait --subscription $SubscriptionId
    }
  }
}
