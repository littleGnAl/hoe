#!/usr/bin/env bash

set -e
set -x

# TAG_NAME="iris_event_20220831"


WINDOWS_RELEASE_VERSION=$(echo "$RELEASE_VERSION" | tr . _)

MY_PATH=$(dirname "$0")

rm -rf $MY_PATH/build
mkdir -p $MY_PATH/build

IRIS_ANDROID_URL=$1
IRIS_IOS_URL=$2
IRIS_MACOS_URL=$3
IRIS_WINDOWS_URL=$4
RELEASE_VERSION=$5

IRIS_ANDROID_UPLOAD_CDN_URL="${IRIS_ANDROID_URL/-api.bj2/}"
IRIS_IOS_UPLOAD_CDN_URL="${IRIS_IOS_URL/-api.bj2/}"
IRIS_MACOS_UPLOAD_CDN_URL="${IRIS_MACOS_URL/-api.bj2/}"
IRIS_WINDOWS_UPLOAD_CDN_URL="${IRIS_WINDOWS_URL/-api.bj2/}"

IRIS_ANDROID_NAME=${IRIS_ANDROID_URL##*/}
IRIS_IOS_NAME=${IRIS_IOS_URL##*/}
IRIS_MACOS_NAME=${IRIS_MACOS_URL##*/}
IRIS_WINDOWS_NAME=${IRIS_WINDOWS_URL##*/}

SDK_CDN_BASE_URL="https://download.agora.io/sdk/release"

JENKINS_UPLOAD_MAVEN_URL=${JENKINS_JOB_IRIS_UPLOAD_MAVEN_URL}
JENKINS_UPLOAD_POD_URL=${JENKINS_JOB_IRIS_UPLOAD_POD_URL}

bash $MY_PATH/upload-manual-cdn-url.sh ${IRIS_ANDROID_UPLOAD_CDN_URL}
bash $MY_PATH/upload-maven.sh ${JENKINS_UPLOAD_MAVEN_URL} $RELEASE_VERSION "${SDK_CDN_BASE_URL}/${IRIS_ANDROID_NAME}" "all.so" "iris-rtc" 1
bash $MY_PATH/notify-wecom.sh ${WECOM_URL} "iris-rtc has been uploaded to maven:\nimplementation 'io.agora.rtc:iris-rtc:${RELEASE_VERSION}'"

bash $MY_PATH/upload-manual-cdn-url.sh ${IRIS_IOS_UPLOAD_CDN_URL}
bash $MY_PATH/upload-cocoapods.sh ${JENKINS_UPLOAD_POD_URL} $RELEASE_VERSION "${SDK_CDN_BASE_URL}/${IRIS_IOS_NAME}" "AgoraIrisRTC_iOS" 1 1
bash $MY_PATH/notify-wecom.sh ${WECOM_URL} "AgoraIrisRTC_iOS has been uploaded to cocoapods:\n'AgoraIrisRTC_iOS', '${RELEASE_VERSION}'"

bash $MY_PATH/upload-manual-cdn-url.sh ${IRIS_MACOS_UPLOAD_CDN_URL}
bash $MY_PATH/upload-cocoapods.sh ${JENKINS_UPLOAD_POD_URL} $RELEASE_VERSION "${SDK_CDN_BASE_URL}/${IRIS_MACOS_NAME}" "AgoraIrisRtc_macOS" 0 1
bash $MY_PATH/notify-wecom.sh ${WECOM_URL} "AgoraIrisRtc_macOS has been uploaded to cocoapods:\n'AgoraIrisRtc_macOS', '${RELEASE_VERSION}'"

bash $MY_PATH/upload-manual-cdn-url.sh ${IRIS_WINDOWS_UPLOAD_CDN_URL}
bash $MY_PATH/notify-wecom.sh ${WECOM_URL} "iris Rtc Windows has been uploaded to cdn:\n${SDK_CDN_BASE_URL}/${IRIS_WINDOWS_NAME}"
