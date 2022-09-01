#!/usr/bin/env bash

set -e
set -x

FILE_PATH=$1


MY_PATH=$(dirname "$0")

JENKINS_CDN_URL=${JENKINS_JOB_MANUAL_CDN_RELEASE_URL}

curl -X POST -L $JENKINS_CDN_URL/build -F file0=@$FILE_PATH -F json='{"parameter": [{"name":"my_file", "file":"file0"},{"name":"TYPE", "value":"sdk"}]}'

bash ${MY_PATH}/wait-jenkins-job-end.sh $JENKINS_CDN_URL


