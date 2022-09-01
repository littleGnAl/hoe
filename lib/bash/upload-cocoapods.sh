#!/usr/bin/env bash

set -e
set -x

JENKINS_UPLOAD_POD_URL=$1
AGORA_SDK_VERSION=$2
RTC_SDK_URL=$3
TYPE=$4
IS_XCFRAMEWORK_PUBLISHED=$5
IS_IRIS_NATIVE_NEEDED=$6

MY_PATH=$(dirname "$0")

curl -X POST -L $JENKINS_UPLOAD_POD_URL/buildWithParameters \
    --data AGORA_SDK_VERSION=${AGORA_SDK_VERSION} \
    --data RTC_SDK_URL=${RTC_SDK_URL} \
    --data TYPE=${TYPE} \
    --data IS_NEED_UPLOAD=true \
    --data IS_XCFRAMEWORK_PUBLISHED=${IS_XCFRAMEWORK_PUBLISHED} \
    --data NEED_RELEASE=1 \
    --data IS_SUBSPEC=0 \
    --data PART_RELEASE_LIST="" \
    --data IS_IRIS_NATIVE_NEEDED=${IS_IRIS_NATIVE_NEEDED}

bash ${MY_PATH}/wait-jenkins-job-end.sh $JENKINS_UPLOAD_POD_URL