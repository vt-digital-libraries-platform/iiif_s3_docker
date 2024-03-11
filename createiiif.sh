#!/bin/bash
# Error out if any command fails
set -e

# Generate random directory and enter it
echo "Creating tmpdir:"
mkdir ./tmp
TMPDIR=$(mktemp -d --tmpdir=$(pwd)/tmp)
echo ${TMPDIR}
cd ${TMPDIR}
cp ../../*.* .
# Create directory structure (IIIF script requires it)
echo "Creating directory structure for IIIF script: ${ACCESS_DIR}"
mkdir -p ${ACCESS_DIR}
# Fetch the images
echo "Fetching images from: s3://${AWS_SRC_BUCKET}/${ACCESS_DIR}"
# Can be helpful to remove "--quiet" flag when testing
aws s3 sync s3://${AWS_SRC_BUCKET}/${ACCESS_DIR} ${ACCESS_DIR}
# Fetch the CSV file
echo "Fetching CSV file from: s3://${AWS_SRC_BUCKET}/${CSV_PATH}/${CSV_NAME}"
aws s3 cp s3://${AWS_SRC_BUCKET}/${CSV_PATH}/${CSV_NAME} .
# Generate the tiles
echo "Calling ruby script to generate tiles with the following arguments:"
echo "COLLECTION_IDENTIFIER: -c ${COLLECTION_IDENTIFIER}"
echo "CSV_NAME: -m ${CSV_NAME}"
echo "ACCESS_DIR: -i ${ACCESS_DIR}"
echo "DEST_URL: -b ${DEST_URL}"
echo "DEST_PREFIX -r: ${DEST_PREFIX}"

AWS_BUCKET_NAME=${AWS_DEST_BUCKET} \
ruby create_iiif_s3.rb -c ${COLLECTION_IDENTIFIER} -m ${CSV_NAME} -i ${ACCESS_DIR}/ -b ${DEST_URL} -r ${DEST_PREFIX}
# Put CSV files in the proper place
echo "Copying CSV file to correct directory"
mkdir -p tmp/${DEST_PREFIX}/${COLLECTION_IDENTIFIER}
cp ${CSV_NAME} tmp/${DEST_PREFIX}/${COLLECTION_IDENTIFIER}/
# Upload generated tiles
echo "Uploading tiles and metadata to dest bucket/path: s3://${AWS_DEST_BUCKET}/${DEST_PREFIX}/"
# Can be helpful to remove "--quiet" flag when testing
aws s3 sync tmp/${DEST_PREFIX}/ s3://${AWS_DEST_BUCKET}/${DEST_PREFIX}/ --quiet
# Delete tmpdir
echo "Cleaning up: Deleting tmpdir ${TMPDIR}"
rm -rf ${TMPDIR}
