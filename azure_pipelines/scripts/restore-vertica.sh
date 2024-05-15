#!/bin/bash

while getopts s:y:m:n:o: flag
do
    case "${flag}" in
        s) storageAccountName=${OPTARG};;
        y) storageAccountVertica=${OPTARG};;
        m) clientID=${OPTARG};;
        n) clientSecret=${OPTARG};;
        o) tenantID=${OPTARG};;
    esac
done


echo "$storageAccountName $storageAccountVertica"
echo "$clientID $clientSecret $tenantID"

tmpFolder="$storageAccountName/containers"
[ -d "$tmpFolder" ] && rm -r "$tmpFolder"
mkdir -p "$tmpFolder"
echo "created"
ls -la
timeStamp=`date +%Y-%m-%d`

cd $storageAccountName
ls 

cd ..
ls

mkdir backups
cd backups

ls

agentpoolIP=$(curl ifconfig.me)
echo "agentpoolIP=${agentpoolIP}"
sleep 5

#Add IPs
echo "Adding IPs to access the private storage accounts"
az storage account network-rule add -g target_architecture_poc --account-name "$storageAccountName" --ip-address "$agentpoolIP"
az storage account network-rule add -g target_architecture_poc --account-name "$storageAccountVertica" --ip-address "$agentpoolIP"

echo "Waiting for IPs to be assgined succesfully"
sleep 60

echo "Upload"

#Directories
dirrecent="https://$storageAccountName.blob.core.windows.net/weekly/latest/$storageAccountVertica/*"
dirvertica="https://$storageAccountVertica.blob.core.windows.net/latest/"

export AZCOPY_SPA_CLIENT_SECRET="$clientSecret"
azcopy login --service-principal --tenant-id "$tenantID" --application-id "$clientID"

sleep 10

echo "Login Status"
azcopy login status

echo "Latest restore starting"
azcopy copy $dirrecent $dirvertica --recursive

echo "Backup Complete"

#Delete IPs
echo "Deleting IPs to access the private storage accounts"
az storage account network-rule remove -g target_architecture_poc --account-name "$storageAccountName" --ip-address "$agentpoolIP"
az storage account network-rule remove -g target_architecture_poc --account-name "$storageAccountVertica" --ip-address "$agentpoolIP"

echo "IP Removed"