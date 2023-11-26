#!/usr/bin/env bash

set -e
set -x

P12_BASE64=$1
P12_PASSWORD=$2

# create variables
# CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
CERTIFICATE_PATH=$3
# PP_PATH=$RUNNER_TEMP/build_pp.mobileprovision
PP_PATH=$4
# GPG_PP_NAME=$4
# KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
KEYCHAIN_PATH=$5
KEYCHAIN_PASSWORD=$6

MY_PATH=$(dirname "$0")

# import certificate and provisioning profile from secrets
# echo -n "$AGORALAB2020_P12_BASE64" | base64 --decode --output $CERTIFICATE_PATH
echo -n "$P12_BASE64" | base64 --decode --output $CERTIFICATE_PATH

# bash ${MY_PATH}/decrypt_secret.sh 



# echo -n "$BUILD_PROVISION_PROFILE_BASE64" | base64 --decode --output $PP_PATH

# create temporary keychain
security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

# import certificate to keychain
security import $CERTIFICATE_PATH -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
security list-keychain -d user -s $KEYCHAIN_PATH

# apply provisioning profile
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp $PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles

UUID=`/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<< $(security cms -D -i $PP_PATH)`
cp "${PP_PATH}" "$HOME/Library/MobileDevice/Provisioning Profiles/$UUID.mobileprovision"