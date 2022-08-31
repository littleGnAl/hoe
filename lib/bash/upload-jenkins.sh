#!/usr/bin/env bash

set -e
set -x

FILE_PATH=$1


MY_PATH=$(dirname "$0")
# source $MY_PATH/setup-env.sh

# JENKINS_CDN_URL=http://10.80.1.18:8080/job/GA/job/Manual_CDN_Release/build
JENKINS_CDN_URL=http://10.80.1.18:8080/job/GA/job/Manual_CDN_Release

# http://10.80.1.18:8080/job/GA/job/Manual_CDN_Release/build
# /Users/fenglang/codes/aw/Agora-Flutter/example/build/macos/Build/Products/Debug/agora_rtc_engine_example.app
curl -X POST -L $JENKINS_CDN_URL/build -F file0=@$FILE_PATH -F json='{"parameter": [{"name":"my_file", "file":"file0"},{"name":"TYPE", "value":"sdk"}]}'

bash ${MY_PATH}/wait-jenkins-job-end.sh $JENKINS_CDN_URL


