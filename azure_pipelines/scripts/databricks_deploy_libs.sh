#!/bin/bash
# Script to deploy Wheel Libraries in Databricks.
# It has has different options to copy the wheel file to DBFS, 
# install the Lib in databricks, remove the libs.  
#
# Functions definition
Help()
{
   # Display Help
   echo "Script to deploy Wheel Libraries in Databricks."
   echo
   echo "Syntax: $0 [-t|c|u|d|r|o|h]"
   echo "options:"
   echo "t     BearerToken to login into Databricks"
   echo "c     Cluster Name"
   echo "u     databribricksURL"
   echo "d     whlDir; Target wheel directory on DBFS"
   echo "s     sourceLib; Source directory where the wheel is copied from"
   echo "o     switch option to ONLY copy data to dbfs"
   echo "r     switch option to remove previous versions from dbfs"
   echo "h     Print this Help."
   echo
   echo "example: $0 -t MyToken -c MyCluster -u https:mydatabricks -d dbfs:/FileStore/Wheels -r -o"
   echo
}
function getClusterId() {
    # Obtain the clusterId from ClusterName received as $1
    name=$1
    clustersList=$(databricks clusters list --output JSON | jq '[ .clusters[] | { name: .cluster_name, id: .cluster_id } ]')
    clusterID=$(echo "$clustersList"|jq --arg NAME $name '.[] | select (.name=="\($NAME)")|.id'|tr -d '"')
    echo "${clusterID}"
}
function uninstallLib() {
    # uninstall library receive 3 Params: libName($1) is Prefix substring of libraryname,
    # clusterId($2) Cluster Id; whlDir($3) directory in dbfs where wheels files are stored.  
    libName=$1
    clusterId=$2
    whlDir=$3
    installedLibs=$(databricks libraries  cluster-status --cluster-id "${clusterId}" | jq '.library_statuses[]? | .library.whl'|tr -d '"')
    for vLib in $installedLibs; do
        if [[ "$vLib" =~ "$libName" ]]; then
            echo "Uninstall Lib: $vLib"
            databricks libraries  uninstall  --cluster-id "${clusterId}" --whl "${vLib}"
        fi
    done
}
function removeLib() {
    # Remove lib from dbfs wheels dir. receive 3 Params: libName($1) is Prefix substring of libraryname,
    #  whlDir($2) directory in dbfs where wheels files are stored.  
    libName=$1
    whlDir=$2
    DownloadedLibs=$(dbfs ls --absolute -l ${whlDir} |awk 'BEGIN {OFS=";"} {print $1,$3}')
    for vLib in $DownloadedLibs; do
        type=$(echo $vLib|cut -d";" -f 1)
        file=$(echo $vLib|cut -d";" -f 2)
        if [[ "$file" =~ "$libName" ]]; then
            echo "Deleting $file"
            dbfs rm $file
        fi
    done
}

function deployLib() {
    # Deploy library copying the lib to dbfs then installing it. Receive 3 Params: sourceLibName($1) is full path from dist,
    # clusterId($2) Cluster Id; whlDir($3) directory in dbfs where wheels files are stored.
    sourceLibName=$1
    clusterId=$2
    whlDir=$3
    echo "Copying ${sourceLibName} to  ${whlDir}"
    dbfs cp $sourceLibName $whlDir --overwrite
    libName="${sourceLibName##*/}"
    rmtLib="${whlDir}/${libName}"
    echo "Installing Lib: ${rmtLib} on cluster  ${clusterId}"
    databricks libraries install  --cluster-id "${clusterId}" --whl "${rmtLib}"
}
function copyLibToDBFS() {
    # Copy library  to dbfs then installing it. Receive 3 Params: sourceLibName($1) is full path from dist,
    # whlDir($3) directory in dbfs where wheels files are stored.
    sourceLibName=$1
    whlDir=$2
    echo "Copying ${sourceLibName} to  ${whlDir}"
    dbfs cp $sourceLibName $whlDir --overwrite
}

#
# Main
while getopts "t:c:u:d:s:rohv" flag
do
    case "${flag}" in
        t) BearerToken=${OPTARG};;
        c) cluster=${OPTARG};;
        u) databricksURL=${OPTARG};;
        d) whlDir=${OPTARG};;
        s) sourceLib=${OPTARG};;
        r) removeLibs=true ;;
        o) copyOnly=true;;
        h) # display Help
            Help
            exit;;
        v) verbose=true ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            echo "Use: $0 -h for Help"
            exit;;
    esac
done

if [ "$verbose" = true ] ; then
    databricks --version
    echo "BearerToken: $BearerToken";
    echo "cluster: $cluster";
    echo "databricksURL: $databricksURL";
    echo "whlDir: $whlDir";
    echo "sourceLib: $sourceLib";
    echo "removeLibs: $removeLibs";
    echo "copyOnly: $copyOnly";
fi

echo "databricksURL ${databricksURL}"
export DATABRICKS_AAD_TOKEN=${BearerToken}
export DATABRICKS_HOST=${databricksURL}
# configure databricks CLI
echo "${databricksURL}
${BearerToken}" | databricks configure --aad-token

# Verify Target wheel directory exists
if [[ "$(dbfs ls ${whlDir})" =~ "RESOURCE_DOES_NOT_EXIST" ]]; then dbfs mkdirs ${whlDir}; fi


# Get cluster ID. If cluster does not exists, create it
clusterId=$(getClusterId "${cluster}")
if [ -z "$clusterId" ]; then 
    # Create cluster
    databricks clusters create --json-file template/cluster_create_template_demo.json
    clusterId=$(getClusterId "${cluster}")
else
    echo "Cluster ${cluster} already exists"
fi
echo "ClusterId: ${clusterId}"
# install libraries.
for distLib in $(ls ${sourceLib}); do
    echo "$distLib"
    libName=$(echo "${distLib##*/}"|cut -d"-" -f 1)
    if [ "$removeLibs" = true ] ; then
        removeLib "${libName}"  "${whlDir}"
    fi
    if [ "$copyOnly" = true ] ; then
        copyLibToDBFS "${distLib}"  "${whlDir}"
    else
        uninstallLib "${libName}"  "${clusterId}"  "${whlDir}"
        deployLib "${distLib}"  "${clusterId}"  "${whlDir}"
    fi
done