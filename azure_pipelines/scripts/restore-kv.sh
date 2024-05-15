while getopts k:s:c:z:a:r: flag
do
    case "${flag}" in
        k) keyvaultName=${OPTARG};;
        s) storageAccountName=${OPTARG};;
        c) container=${OPTARG};;
        z) zipFile=${OPTARG};;
        r) secretRestore=${OPTARG};;
    esac
done

tmpFolder="./tmp-folder"
[ -d "$tmpFolder" ] && rm -r "$tmpFolder"
mkdir "$tmpFolder"

echo "Starting download of backup to Az Files"
az storage blob download --account-name "$storageAccountName" --auth-mode login \
  --container-name "$container" \
  --name "$zipFile" \
  --file backup.zip \

# Uncompress backup
unzip backup.zip -d "$tmpFolder"

cd "$tmpFolder"

# Secrets List
echo "Secrets:" >> secrets.txt
ls | grep "secret-" >> secrets.txt
secretsList="$(cat secrets.txt)"
# Certificates List
echo "Certificates:" >> certificates.txt
ls | grep "certificate-" >> certificates.txt
certificatesList=$(cat certificates.txt)
# Keys List
echo "Keys:" >> keys.txt
ls | grep "key-" >> keys.txt
keysList=$(cat keys.txt)

# Restore secrets to KV
if [[ -z "$secretRestore" ]]; then
  for file in secret-*; do
    echo "Restoring $file"
    az keyvault secret restore --file "./$file" --vault-name $keyvaultName
  done
elif [[ "$secretRestore" == *"all"* ]]; then
  for file in secret-*; do
    echo "Restoring $file"
    az keyvault secret restore --file "./$file" --vault-name $keyvaultName
  done
elif [[ "$secretRestore" == *"secret-"* ]]; then
  echo "Restoring $secretRestore"
  az keyvault secret restore --file "./$secretRestore" --vault-name $keyvaultName
else
  echo "Doesn't exist $secretRestore. Please check the follwing list to choose the correct option: "
  cat "$secretsList"
fi

# for file in secret-*; do
#   echo "Restoring $file"
#   az keyvault secret restore --file "./$file" --vault-name $keyvaultName
# done

# Restore certificates to KV
if [[ -z "$certificateRestore" ]]; then
  for file in certificate-*; do
    echo "Restoring $file"
    az keyvault secret restore --file "./$file" --vault-name $keyvaultName
  done
elif [[ "$certificateRestore" == *"all"* ]]; then
  for file in certificate-*; do
    echo "Restoring $file"
    az keyvault secret restore --file "./$file" --vault-name $keyvaultName
  done
elif [[ "$certificateRestore" == *"certificate-"* ]]; then
  echo "Restoring $certificateRestore"
  az keyvault secret restore --file "./$certificateRestore" --vault-name $keyvaultName
else
  echo "Doesn't exist $certificateRestore. Please check the follwing list to choose the correct option: "
  cat $certificatesList
fi


# for file in certificate-*; do
#   echo "Restoring $file"
#   az keyvault certificate restore --file "./$file" --vault-name $keyvaultName
# done

# Restore keys to KV
if [[ -z "$keyRestore" ]]; then
  for file in key-*; do
    echo "Restoring $keyRestore"
    az keyvault secret restore --file "./$file" --vault-name $keyvaultName
  done
elif [[ "$keyRestore" == *"all"* ]]; then
  for file in key-*; do
    echo "Restoring $keyRestore"
    az keyvault secret restore --file "./$file" --vault-name $keyvaultName
  done
elif [[ "$keyRestore" == *"key-"* ]]; then
  echo "Restoring $keyRestore"
  az keyvault secret restore --file "./$keyRestore" --vault-name $keyvaultName
else
  echo "Doesn't exist $keyRestore. Please check the follwing list to choose the correct option: "
  cat $keysList
fi


# for file in key-*; do
#   echo "Restoring $file"
#   az keyvault key restore --file "./$file" --vault-name $keyvaultName
# done

cd ..

rm -r "$tmpFolder"
rm ./backup.zip

echo "Restore Complete"