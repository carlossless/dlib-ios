#!/usr/bin/env bash

set -e pipefail

DLIB_VERSION="19.17"
IOS_CMAKE_VERSION="3.0.2"

[ ! -d dlib ] && curl -fsSL "https://github.com/davisking/dlib/archive/v$DLIB_VERSION.tar.gz" | tar xz && mv "dlib-$DLIB_VERSION" dlib
[ ! -d ios-cmake ] && curl -fsSL "https://github.com/leetal/ios-cmake/archive/$IOS_CMAKE_VERSION.tar.gz" | tar xz && mv "ios-cmake-$IOS_CMAKE_VERSION" ios-cmake

mkdir -p build
cd build

cmake ../dlib/dlib -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE=../ios-cmake/ios.toolchain.cmake \
  -DCMAKE_INSTALL_PREFIX=install \
  -DPLATFORM=OS64COMBINED \
  -DLIBPNG_IS_GOOD=0 \
  -DDLIB_NO_GUI_SUPPORT=0 \
  -DDLIB_USE_CUDA=0 \
  -DDLIB_USE_BLAS=0 \
  -DDLIB_USE_LAPACK=0

cmake --build . --config Release --target install

FRAMEWORK_VERSION=$DLIB_VERSION
HEADER_SUFFIX=".h"
CURRENT_FOLDER=`pwd`
FRAMEWORK_NAME="dlib"
FRAMEWORK_EXT=".framework"
FRAMEWORK="$FRAMEWORK_NAME$FRAMEWORK_EXT"
BUILD_FOLDER="$CURRENT_FOLDER/build"
BUILD_INCLUDE_FOLDER="$BUILD_FOLDER/install/include/dlib"
BUILD_LIB_FOLDER="$BUILD_FOLDER/install/lib"
OUTPUT_FOLDER="$CURRENT_FOLDER/$FRAMEWORK"
OUTPUT_INFO_PLIST_FILE="$OUTPUT_FOLDER/Info.plist"
OUTPUT_HEADER_FOLDER="$OUTPUT_FOLDER/Headers"
OUTPUT_UMBRELLA_HEADER="$OUTPUT_HEADER_FOLDER/dlib.h"
OUTPUT_MODULES_FOLDER="$OUTPUT_FOLDER/Modules"
OUTPUT_MODULES_FILE="$OUTPUT_MODULES_FOLDER/module.modulemap"
VERSION_NEW_NAME="Version.h"
BUNDLE_ID="io.carlossless.dlib"

export FRAMEWORK_VERSION

function create_framework() {
  rm -rf $OUTPUT_FOLDER
  mkdir -p $OUTPUT_HEADER_FOLDER $OUTPUT_MODULES_FOLDER
}

function copy_headers() {
  pushd "$(pwd)/install/include/dlib"
  find . -name "*.h" | cpio -pdm $OUTPUT_HEADER_FOLDER
  popd
}

function copy_lib () {
  cp "$(pwd)/install/lib/libdlib.a" "$OUTPUT_FOLDER/dlib"
}

function create_umbrella_header() {
  [[ $FRAMEWORK_VERSION =~ ^([0-9]+.[0-9]+).*$ ]]
  SHORT_FRAMEWORK_VERSION=${BASH_REMATCH[1]}
  cat > $OUTPUT_UMBRELLA_HEADER <<EOF
#import <Foundation/Foundation.h>
#currently this is just empty
double dlibVersionNumber = ${SHORT_FRAMEWORK_VERSION};
EOF
}

function create_modulemap() {
  cat > $OUTPUT_MODULES_FILE <<EOF
framework module $FRAMEWORK_NAME {
  umbrella header "dlib.h"
  export *
  module * { export * }
}
EOF
}

function create_info_plist() {
  DEFAULT_iOS_SDK_VERSION=`defaults read $(xcode-select -p)/Platforms/iPhoneOS.platform/version CFBundleShortVersionString`
  DTCompiler=`defaults read $(xcode-select -p)/../info DTCompiler`
  DTPlatformBuild=`defaults read $(xcode-select -p)/../info DTPlatformBuild`
  DTSDKBuild=`defaults read $(xcode-select -p)/../info DTSDKBuild`
  DTXcode=`defaults read $(xcode-select -p)/../info DTXcode`
  DTXcodeBuild=`defaults read $(xcode-select -p)/../info DTXcodeBuild`
  OS_BUILD_VERSION=$(sw_vers -buildVersion)
  cat > $OUTPUT_INFO_PLIST_FILE <<EOF
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
          <key>BuildMachineOSBuild</key>
          <string>$OS_BUILD_VERSION</string>
          <key>CFBundleDevelopmentRegion</key>
          <string>en</string>
          <key>CFBundleExecutable</key>
          <string>$FRAMEWORK_NAME</string>
          <key>CFBundleIdentifier</key>
          <string>$BUNDLE_ID</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundleName</key>
          <string>$FRAMEWORK_NAME</string>
          <key>CFBundlePackageType</key>
          <string>FMWK</string>
          <key>CFBundleShortVersionString</key>
          <string>$FRAMEWORK_VERSION</string>
          <key>CFBundleSignature</key>
          <string>????</string>
          <key>CFBundleSupportedPlatforms</key>
          <array>
          <string>iPhoneOS</string>
          </array>
          <key>CFBundleVersion</key>
          <string>1</string>
          <key>DTCompiler</key>
          <string>$DTCompiler</string>
          <key>DTPlatformBuild</key>
          <string>$DTPlatformBuild</string>
          <key>DTPlatformName</key>
          <string>iphoneos</string>
          <key>DTPlatformVersion</key>
          <string>$DEFAULT_iOS_SDK_VERSION</string>
          <key>DTSDKBuild</key>
          <string>$DTSDKBuild</string>
          <key>DTSDKName</key>
          <string>iphoneos$DEFAULT_iOS_SDK_VERSION</string>
          <key>DTXcode</key>
          <string>$DTXcode</string>
          <key>DTXcodeBuild</key>
          <string>$DTXcodeBuild</string>
          <key>MinimumOSVersion</key>
          <string>8.0</string>
          <key>UIDeviceFamily</key>
          <array>
          <integer>1</integer>
          <integer>2</integer>
          </array>
  </dict>
  </plist>
EOF
}

create_framework
copy_headers
copy_lib
create_umbrella_header
create_modulemap
create_info_plist
