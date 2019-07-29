#!/usr/bin/env bash

set -e pipefail

export PATH=$(pwd)/build:$PATH

TEST_SOURCE=dlib/examples/bsp_ex.cpp
FRAMEWORK_OPTS="-framework Foundation -framework dlib -Fbuild"

echo "Testing iphoneos build"
xcrun -sdk iphoneos clang++ -fobjc-arc -std=c++11 -arch arm64 $FRAMEWORK_OPTS -o /dev/null $TEST_SOURCE
echo "Testing iphonesimulator build"
xcrun -sdk iphonesimulator clang++ -fobjc-arc -std=c++11 -arch x86_64 $FRAMEWORK_OPTS -framework Foundation -framework dlib -o /dev/null $TEST_SOURCE
