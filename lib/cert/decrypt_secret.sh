#!/usr/bin/env bash

set -e
set -x

OUTPUT_FILE_PATH=$1
GPG_FILE_PATH=$2
# DECRYPT_FILE_NAME=$2
SECRET_PASSPHRASE=$3

gpg --quiet --batch --yes --decrypt --passphrase="$SECRET_PASSPHRASE" \
    --output ${OUTPUT_FILE_PATH} ${GPG_FILE_PATH}