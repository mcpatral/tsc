#!/bin/bash

ROOT_DIR=local_disk0
TGT_PACKAGE_DIR=intrum_packages
FULL_TGT_DIR=/$ROOT_DIR/$TGT_PACKAGE_DIR
SRC_PACKAGE_DIR=/dbfs/FileStore/wheels

cd $ROOT_DIR

# remove it every time the cluster starts to have a clean environment
rm -rf $TGT_PACKAGE_DIR

for file in "$SRC_PACKAGE_DIR"/*.whl; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        filename_no_ext="${filename%.whl}"		
		# target directory will be created automatically
		pip install --target=$FULL_TGT_DIR/$filename_no_ext $SRC_PACKAGE_DIR/$filename
    fi
done