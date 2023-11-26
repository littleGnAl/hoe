#!/usr/bin/env bash

set -e
set -x

WECOM_URL=$1

CONTENT=$2

MY_PATH=$(dirname "$0")


curl ${WECOM_URL} \
   -H 'Content-Type: application/json' \
   -d "
   {
        \"msgtype\": \"text\",
        \"text\": {
            \"content\": \"${CONTENT}\"
        }
   }"