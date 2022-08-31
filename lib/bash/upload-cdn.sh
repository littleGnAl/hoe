#!/usr/bin/env bash

set -e
set -x

# TAG_NAME="iris_event_20220831"
TAG_NAME=$1
RELEASE_VERSION=$2

WINDOWS_RELEASE_VERSION=$(echo "$RELEASE_VERSION" | tr . _)

MY_PATH=$(dirname "$0")

rm -rf $MY_PATH/build
mkdir -p $MY_PATH/build

IRIS_EVENT_ANDROID_NAME="Agora_Iris_Event_Flutter_for_Android.zip"
IRIS_EVENT_IOS_NAME="Agora_Iris_Event_Flutter_for_iOS.zip"
IRIS_EVENT_MACOS_NAME="Agora_Iris_Event_Flutter_for_macOS.zip"
IRIS_EVENT_WINDOWS_NAME="Agora_Iris_Event_Flutter_for_Windows.zip"

dt=$(date '+%Y%m%d%H%M%S')

IRIS_EVENT_ANDROID_DOWNLOAD_NAME="Agora_Iris_Event_Flutter_for_Android_${dt}.zip"
IRIS_EVENT_IOS_DOWNLOAD_NAME="Agora_Iris_Event_Flutter_for_iOS_${dt}.zip"
IRIS_EVENT_MACOS_DOWNLOAD_NAME="Agora_Iris_Event_Flutter_for_macOS_${dt}.zip"
IRIS_EVENT_WINDOWS_DOWNLOAD_NAME="Agora_Iris_Event_Flutter_for_Windows_v${WINDOWS_RELEASE_VERSION}.zip"

GITHUB_RELEASE_BASE_URL="https://github.com/AgoraIO-Extensions/iris_event_flutter/releases/download"
SDK_CDN_BASE_URL="https://download.agora.io/sdk/release"

JENKINS_UPLOAD_MAVEN_URL="http://10.80.1.18:8080/job/GA/job/Agora-Publish-Jcenter_test"
JENKINS_UPLOAD_POD_URL="http://10.80.1.18:8080/job/GA/job/Pod_Package_Test"

curl -L "$GITHUB_RELEASE_BASE_URL/$TAG_NAME/$IRIS_EVENT_ANDROID_NAME" > $MY_PATH/build/$IRIS_EVENT_ANDROID_DOWNLOAD_NAME
bash $MY_PATH/upload-jenkins.sh $MY_PATH/build/$IRIS_EVENT_ANDROID_DOWNLOAD_NAME
bash $MY_PATH/upload-maven.sh ${JENKINS_UPLOAD_MAVEN_URL} $RELEASE_VERSION "${SDK_CDN_BASE_URL}/${IRIS_EVENT_ANDROID_DOWNLOAD_NAME}" "libiris_event_handler.so" "iris-event-flutter" 0
bash $MY_PATH/notify-wecom.sh $WECOM_URL "iris-event-flutter has been uploaded to maven:\nimplementation 'io.agora.rtc:iris-event-flutter:${RELEASE_VERSION}'"

curl -L "$GITHUB_RELEASE_BASE_URL/$TAG_NAME/$IRIS_EVENT_IOS_NAME" > $MY_PATH/build/$IRIS_EVENT_IOS_DOWNLOAD_NAME
bash $MY_PATH/upload-jenkins.sh $MY_PATH/build/$IRIS_EVENT_IOS_DOWNLOAD_NAME
bash $MY_PATH/upload-cocoapods.sh ${JENKINS_UPLOAD_POD_URL} $RELEASE_VERSION "${SDK_CDN_BASE_URL}/${IRIS_EVENT_IOS_DOWNLOAD_NAME}" "AgoraIrisEventFlutter_iOS" 1 0
bash $MY_PATH/notify-wecom.sh $WECOM_URL "AgoraIrisEventFlutter_iOS has been uploaded to cocoapods:\n'AgoraIrisEventFlutter_iOS', '${RELEASE_VERSION}'"

curl -L "$GITHUB_RELEASE_BASE_URL/$TAG_NAME/$IRIS_EVENT_MACOS_NAME" > $MY_PATH/build/$IRIS_EVENT_MACOS_DOWNLOAD_NAME
bash $MY_PATH/upload-jenkins.sh $MY_PATH/build/$IRIS_EVENT_MACOS_DOWNLOAD_NAME
bash $MY_PATH/upload-cocoapods.sh ${JENKINS_UPLOAD_POD_URL} $RELEASE_VERSION "${SDK_CDN_BASE_URL}/${IRIS_EVENT_MACOS_DOWNLOAD_NAME}" "AgoraIrisEventFlutter_macOS" 0 0
bash $MY_PATH/notify-wecom.sh $WECOM_URL "AgoraIrisEventFlutter_macOS has been uploaded to cocoapods:\n'AgoraIrisEventFlutter_macOS', '${RELEASE_VERSION}'"

curl -L "$GITHUB_RELEASE_BASE_URL/$TAG_NAME/$IRIS_EVENT_WINDOWS_NAME" > $MY_PATH/build/$IRIS_EVENT_WINDOWS_DOWNLOAD_NAME
bash $MY_PATH/upload-jenkins.sh $MY_PATH/build/$IRIS_EVENT_WINDOWS_DOWNLOAD_NAME
bash $MY_PATH/notify-wecom.sh $WECOM_URL "Agora_Iris_Event_Flutter_for_Windows has been uploaded to cdn:\n${SDK_CDN_BASE_URL}/${IRIS_EVENT_WINDOWS_DOWNLOAD_NAME}"
