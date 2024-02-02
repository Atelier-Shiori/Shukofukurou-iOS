#!/bin/bash

set -e
set -o pipefail

XCODE_VERSION=$(xcodebuild -version | head -n 1| awk -F ' ' '{print $2}')
XCODE_VERSION_MAJOR=$(echo $XCODE_VERSION | awk -F '.' '{print $1}')
if [ -z "$SRCROOT" ]
then
    SRCROOT=$(pwd)
fi

mkdir -p "${SRCROOT}/build"
PLATFORMS=("iOS" "iOSSimulator" "macOS" "tvOS" "tvOSSimulator" "watchOS" "watchOSSimulator")

if [ $XCODE_VERSION_MAJOR -ge 11 ]
then
    PLATFORMS+=("macCatalyst")
fi

if [ $XCODE_VERSION_MAJOR -ge 15 ]
then
    PLATFORMS+=("visionOS")
    PLATFORMS+=("visionOSSimulator")
fi

for CURRENT_PLATFORM in "${PLATFORMS[@]}"
do
    DESTINATION="generic/platform=${CURRENT_PLATFORM}"

    # macOS Catalyst
    if [[ $CURRENT_PLATFORM == "macCatalyst" ]]; then
        DESTINATION="generic/platform=macOS,variant=Mac Catalyst"
    fi

    # Simulator
    if [[ $CURRENT_PLATFORM == *Simulator ]]; then
        CURRENT_PLATFORM_OS=${CURRENT_PLATFORM%Simulator}
        DESTINATION="generic/platform=${CURRENT_PLATFORM_OS} Simulator"
    fi

    xcodebuild build -project "SDWebImage.xcodeproj" -destination "${DESTINATION}" -scheme "SDWebImage" -configuration "Release" -derivedDataPath "${SRCROOT}/build/DerivedData" CONFIGURATION_BUILD_DIR="${SRCROOT}/build/${CURRENT_PLATFORM}/"
done
