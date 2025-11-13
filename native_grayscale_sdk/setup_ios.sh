#!/bin/bash

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="$SCRIPT_DIR"
NATIVE_APP_DIR="$SCRIPT_DIR/../native_grayscale_sample_app"

cd "$NATIVE_APP_DIR"
rm -rf NativeGrayscaleSDK
rm -rf NativeGrayscaleSDK.xcodeproj

cd "$SDK_DIR/flutter"
flutter clean
flutter pub get

# .ios 폴더가 없으면 Flutter 모듈 생성
if [ ! -d ".ios" ]; then
    echo "Creating .ios folder for Flutter module..."
    flutter create --template module .
fi

flutter build ios-framework --xcframework --output=../out/ios --no-profile --no-release --no-plugins

cd "$SDK_DIR/ios/NativeGrayscaleSDK"
rm -rf Frameworks
ln -s ../../out/ios/Debug Frameworks

cd "$NATIVE_APP_DIR"
pod install --repo-update

ln -sf "$SDK_DIR/ios/NativeGrayscaleSDK" NativeGrayscaleSDK
ln -sf "$SDK_DIR/ios/NativeGrayscaleSDK.xcodeproj" NativeGrayscaleSDK.xcodeproj

