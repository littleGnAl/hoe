#!/usr/bin/env bash

set -e
set -x

WORKING_DIR=$1
OUTPUT_ZIP_PATH=$2
ZIP_DIR=$3

pushd ${WORKING_DIR}
zip -r -y "${OUTPUT_ZIP_PATH}" ${ZIP_DIR}
popd