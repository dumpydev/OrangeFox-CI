#!/usr/bin/env bash

set -o pipefail

# Constants
MANIFEST="https://github.com/PitchBlackRecoveryProject/manifest_pb.git"
MANIFEST_BRANCH="android-12.1"
DEVICE="RM2111"
DT_LINK="https://github.com/dumpydev/android_device_realme_RMX2111-pbrp"
DT_BRANCH="android-11.0-cirrus"
DT_PATH="device/realme/RM2111"
n=$'\n'

git config --global user.email "dumpyee09@gmail.com"
git config --global user.name "flumpy"

df -h
mkdir work
cd work

# Setup transfer
curl -sL https://git.io/file-transfer | sh

repo init --depth=1 -u "$MANIFEST" -b "$MANIFEST_BRANCH"
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags

git clone "$DT_LINK" --depth=1 --single-branch -b "$DT_BRANCH" "$DT_PATH"

. build/envsetup.sh && \
    lunch "omni_$DEVICE-eng" && \
    { make -j8 pbrp | tee -a "build_$DEVICE.log" || fail; } &

file_link=$(./transfer --silent wet out/target/product/$DEVICE/recovery.img)
