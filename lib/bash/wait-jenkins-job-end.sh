#!/usr/bin/env bash

set -e
set -x

FILE_PATH=$1

MY_PATH=$(dirname "$0")

JENKINS_CDN_URL=$1

sleep 10
RESULT=$(curl -X GET -L "${JENKINS_CDN_URL}/lastBuild/buildNumber")

JOB_STATUS_URL=${JENKINS_CDN_URL}/${RESULT}/api/json

python3 ${MY_PATH}/wait-jenkins-job-end.py $JOB_STATUS_URL

echo "$JENKINS_CDN_URL Build finished"


