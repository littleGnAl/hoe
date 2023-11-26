#!/usr/bin/env bash

set -e
set -x

RTC_SDK_URL=$1


MY_PATH=$(dirname "$0")

JENKINS_CDN_URL=${JENKINS_JOB_MANUAL_CDN_RELEASE_URL_URL}

curl -X POST -L $JENKINS_CDN_URL/buildWithParameters \
    --data RTC_SDK_URL=${RTC_SDK_URL} \
    --data CDN_FILE_NAME="" \
    --data TYPE="sdk"

bash ${MY_PATH}/wait-jenkins-job-end.sh $JENKINS_CDN_URL

bash ${MY_PATH}/notify-wecom.sh ${WECOM_URL} "CDN uploaded: ${JENKINS_CDN_URL}"


