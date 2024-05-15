while getopts k:s:c: flag
do
    case "${flag}" in
      k) keyvaultName=${OPTARG};;
      s) storageAccountName=${OPTARG};;
      c) container=${OPTARG};;
    esac
done

tmpFolder=$keyvaultName
[ -d "$tmpFolder" ] && rm -r "$tmpFolder"
mkdir "$tmpFolder"

echo "Starting backup of KeyVault certificates to local directory"
# Certificates
readarray -t certificates < <(az keyvault certificate list --vault-name $keyvaultName | jq -c '.[]')

for cert in "${certificates[@]}"; do
    obj_id=$(echo $cert | jq '.id')
    obj_id="${obj_id%\"}"
    obj_id="${obj_id#\"}"
    obj_name=$(echo $cert | jq '.name')
    obj_name="${obj_name%\"}"
    obj_name="${obj_name#\"}"
    az keyvault certificate backup --file "$tmpFolder/certificate-$obj_name" --id "$obj_id" 
done

echo "Starting backup of KeyVault secrets to local directory"
# Secrets
readarray -t secrets < <(az keyvault secret list --vault-name $keyvaultName | jq -c '.[]')

for secret in "${secrets[@]}"; do
    obj_id=$(echo $secret | jq '.id')
    obj_id="${obj_id%\"}"
    obj_id="${obj_id#\"}"
    obj_name=$(echo $secret | jq '.name')
    obj_name="${obj_name%\"}"
    obj_name="${obj_name#\"}"
    test=""
    test="$(echo $certificates | grep '$obj_name')"
    if [[ "$test" -eq "" ]]; then
      az keyvault secret backup --file "$tmpFolder/secret-$obj_name" --id "$obj_id" 
    fi
done

echo "Starting backup of KeyVault keys to local directory"
# keys
readarray -t keys < <(az keyvault key list --vault-name $keyvaultName | jq -c '.[]')

for key in "${keys[@]}"; do
    obj_id=$(echo $key | jq '.kid')
    obj_id="${obj_id%\"}"
    obj_id="${obj_id#\"}"
    obj_name=$(echo $key | jq '.name')
    obj_name="${obj_name%\"}"
    obj_name="${obj_name#\"}"
    test=""
    test="$(echo $certificates | grep '$obj_name')"
    if [[ "$test" -eq "" ]]; then
      az keyvault key backup --file "$tmpFolder/key-$obj_name" --id "$obj_id" 
    fi
done

echo "Local file backup complete"  

timeStamp=`date +%Y-%m-%d`
zipFile="$keyvaultName-$timeStamp.zip"
cd "$tmpFolder"
zip "../$zipFile" ./*
cd ..

# ---- BLOCK SHOULD BE COMMENTED. NOT REQUIRED WHEN USING AGENT POOL DEFAULT WITH PRIVATE AKS PEERED WITH ENV VNET ----
# az storage account network-rule add -g target_architecture_poc \
#   --account-name "$storageAccountName" \
#   --ip-address "$agentpoolIP"
# ---- END OF BLOCK ----

# upload files, overwriting existing
echo "Starting upload of backup to zip Files"
timeStamp2=`date +%Y%m%d`
az storage blob upload --account-name "$storageAccountName" --auth-mode login \
  --container-name "$container" \
  --name "$timeStamp2/$keyvaultName/$zipFile" \
  --file "$zipFile" \
  --tier "Cool"

rm -r "$tmpFolder"

echo "Backup Complete"