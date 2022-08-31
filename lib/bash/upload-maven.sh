#!/usr/bin/env bash

set -e
set -x

JENKINS_UPLOAD_POD_URL=$1
AGORA_SDK_VERSION=$2
RTC_SDK_URL=$3
SO_LIST=$4
REPO_NAME=$5
IS_IRIS_NATIVE_NEEDED=$6

MY_PATH=$(dirname "$0")

# JENKINS_UPLOAD_POD_URL=http://10.80.1.18:8080/job/GA/job/Agora-Publish-Jcenter_test

curl -X POST -L $JENKINS_UPLOAD_POD_URL/buildWithParameters \
    --data AGORA_SDK_VERSION=${AGORA_SDK_VERSION} \
    --data PRODUCT="Common" \
    --data RTC_SDK_URL=${RTC_SDK_URL} \
    --data BUILD_BRANCH="master" \
    --data BUILD_TIMESTAMP=0 \
    --data SO_LIST=${SO_LIST} \
    --data COMMON_RELEASE_TYPE="build_all" \
    --data REPO_NAME=${REPO_NAME} \
    --data IS_IRIS_NATIVE_NEEDED=${IS_IRIS_NATIVE_NEEDED}

bash ${MY_PATH}/wait-jenkins-job-end.sh $JENKINS_UPLOAD_POD_URL