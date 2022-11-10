#!/usr/bin/env bash

set -o pipefail

curl -sL https://raw.githubusercontent.com/Hakimi0804/tgbot/main/util.sh -o util.sh
source util.sh

# Constants
MANIFEST="https://github.com/PitchBlackRecoveryProject/manifest_pb.git"
MANIFEST_BRANCH="android-12.1"
DEVICE="RM2111"
DT_LINK="https://github.com/dumpydev/android_device_realme_RMX2111-pbrp"
DT_BRANCH="android-11.0-cirrus"
DT_PATH="device/realme/RM2111"
n=$'\n'

CHAT_ID=-1001664444944
MSG_TITLE=(
    $'Building recovery for realme 7 5G/RM2111\n'
)

git config --global user.email "dumpyee09@gmail.com"
git config --global user.name "flumpy"

df -h
mkdir work
cd work

# Setup transfer
curl -sL https://git.io/file-transfer | sh

updateProg() {
    BUILD_PROGRESS=$(
            sed -n '/ ninja/,$p' "build_$DEVICE.log" | \
            grep -Po '\d+% \d+/\d+' | \
            tail -n1 | \
            sed -e 's/ / \(/' -e 's/$/)/'
        )
}

editProg() {
    if [ -z "$BUILD_PROGRESS" ]; then
        return
    fi
    if [ "$BUILD_PROGRESS" = "$PREV_BUILD_PROGRESS" ]; then
        return
    fi
    tg --editmsg "$CHAT_ID" "$SENT_MSG_ID" "${MSG_TITLE[*]}Progress: $BUILD_PROGRESS"
    PREV_BUILD_PROGRESS=$BUILD_PROGRESS
}

fail() {
    BUILD_PROGRESS=failed
    editProg
    exit 1
}

tg --sendmsg "$CHAT_ID" "${MSG_TITLE[*]}Progress: Syncing repo"

repo init --depth=1 -u "$MANIFEST" -b "$MANIFEST_BRANCH"
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags

git clone "$DT_LINK" --depth=1 --single-branch -b "$DT_BRANCH" "$DT_PATH"
MSG_TITLE+=($'\nBuilding for RMX2111\n')
. build/envsetup.sh && \
    lunch "omni_$DEVICE-eng" && \
    { make -j8 pbrp | tee -a "build_$DEVICE.log" || fail; } &

until [ -z "$(jobs -r)" ]; do
    updateProg
    editProg
    sleep 5
done

updateProg
editProg
file_link=$(./transfer --silent wet out/target/product/$DEVICE/recovery.img)
MSG_TITLE+=("RMX2111 link: $file_link$n")
