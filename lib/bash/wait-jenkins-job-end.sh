#!/usr/bin/env bash

set -e
set -x

FILE_PATH=$1


MY_PATH=$(dirname "$0")
# source $MY_PATH/setup-env.sh

# JENKINS_CDN_URL=http://10.80.1.18:8080/job/GA/job/Manual_CDN_Release/build
JENKINS_CDN_URL=$1

# http://10.80.1.18:8080/job/GA/job/Manual_CDN_Release/build
# /Users/fenglang/codes/aw/Agora-Flutter/example/build/macos/Build/Products/Debug/agora_rtc_engine_example.app
sleep 10
RESULT=$(curl -X GET -L "${JENKINS_CDN_URL}/lastBuild/buildNumber")


JOB_STATUS_URL=${JENKINS_CDN_URL}/${RESULT}/api/json

GREP_RETURN_CODE=0

while [ $GREP_RETURN_CODE -eq 0 ]
do
    sleep 10
    # Grep will return 0 while the build is running:
    curl --silent $JOB_STATUS_URL | grep result\":null > /dev/null || if [ "$?" == "1" ]; then
       exit 0
    fi

    GREP_RETURN_CODE=$?
done
echo "$JENKINS_CDN_URL Build finished"


