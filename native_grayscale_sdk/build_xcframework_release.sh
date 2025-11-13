#!/bin/bash
set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="$SCRIPT_DIR"
NATIVE_APP_DIR="$SCRIPT_DIR/../native_grayscale_sample_app"

export FRAMEWORK_NAME="NativeGrayscaleSDK"
export BUILD_DIR="${SDK_DIR}/out/ios"
export RELEASE_BUILD_DIR="${BUILD_DIR}/Release"
START_TIME=$SECONDS

# Clean build directory
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Removing $BUILD_DIR..."
    chmod -R 755 "$BUILD_DIR" 2>/dev/null || true
    rm -rf "$BUILD_DIR"
fi

# Clean native app symlinks and recreate
cd "$NATIVE_APP_DIR"
rm -rf "$FRAMEWORK_NAME"
rm -rf "$FRAMEWORK_NAME.xcodeproj"

# Build Flutter framework
cd "$SDK_DIR/flutter"
flutter clean
flutter pub get

# .ios 폴더가 없으면 Flutter 모듈 생성
if [ ! -d ".ios" ]; then
    echo "Creating .ios folder for Flutter module..."
    flutter create --template module .
fi

# Build iOS framework with obfuscation and debug symbols
flutter build ios-framework --xcframework --output=../out/ios --no-profile --obfuscate --split-debug-info=./symbols

cd "$SDK_DIR"

# Clean .build directory
if [ -d ".build" ]; then
    rm -rf .build
fi

# Setup Release framework symlink
cd "$SDK_DIR/ios/$FRAMEWORK_NAME"
rm -rf Frameworks
ln -s ../../out/ios/Release Frameworks
cd "$SDK_DIR/ios"

# Build RELEASE xcframework
echo "$FRAMEWORK_NAME Archiving for RELEASE iphoneos..."
xcodebuild archive \
    -project "$FRAMEWORK_NAME.xcodeproj" \
    -scheme "$FRAMEWORK_NAME" \
    -sdk "iphoneos" \
    -configuration "Release" \
    -destination "generic/platform=iOS" \
    -archivePath "$RELEASE_BUILD_DIR/ios-arm64-release.xcarchive" \
    -derivedDataPath "$SDK_DIR/.build" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "$FRAMEWORK_NAME Archiving for RELEASE simulator..."
xcodebuild archive \
    -project "$FRAMEWORK_NAME.xcodeproj" \
    -scheme "$FRAMEWORK_NAME" \
    -sdk "iphonesimulator" \
    -configuration "Release" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$RELEASE_BUILD_DIR/ios-simulator-release.xcarchive" \
    -derivedDataPath "$SDK_DIR/.build" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Remove nested Frameworks folder from built frameworks (like chatting-plus-sdk)
echo "Removing nested Frameworks folder from RELEASE frameworks..."
rm -rf "$RELEASE_BUILD_DIR/ios-arm64-release.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework/Frameworks" 2>/dev/null || true
rm -rf "$RELEASE_BUILD_DIR/ios-simulator-release.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework/Frameworks" 2>/dev/null || true

echo "$FRAMEWORK_NAME Merging for RELEASE frameworks..."
xcodebuild -verbose -create-xcframework \
    -framework "$RELEASE_BUILD_DIR/ios-arm64-release.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -debug-symbols "$RELEASE_BUILD_DIR/ios-arm64-release.xcarchive/dSYMs/$FRAMEWORK_NAME.framework.dSYM" \
    -framework "$RELEASE_BUILD_DIR/ios-simulator-release.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -output "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework"

# Clean up archive directories
rm -rf "$RELEASE_BUILD_DIR/ios-arm64-release.xcarchive"
rm -rf "$RELEASE_BUILD_DIR/ios-simulator-release.xcarchive"

# Code signing
cd "$SDK_DIR"

echo "Code signing RELEASE $FRAMEWORK_NAME.xcframework..."
rm -rf "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework/release-iphoneos.xcarchive" 2>/dev/null || true
codesign --remove-signature "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework/ios-arm64/$FRAMEWORK_NAME.framework" 2>/dev/null || true
codesign --remove-signature "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework/ios-arm64_x86_64-simulator/$FRAMEWORK_NAME.framework" 2>/dev/null || true
codesign --remove-signature "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework" 2>/dev/null || true
codesign --force --deep --sign - "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework"

echo "Code signing RELEASE grayscale.xcframework..."
# rm -rf "$RELEASE_BUILD_DIR/$FRAMEWORK_NAME.xcframework/ios-arm64_x86_64-simulator/grayscale.framework/release-iphoneos.xcarchive" 2>/dev/null || true
codesign --remove-signature "$RELEASE_BUILD_DIR/grayscale.xcframework/ios-arm64/grayscale.framework" 2>/dev/null || true
codesign --remove-signature "$RELEASE_BUILD_DIR/grayscale.xcframework/ios-arm64_x86_64-simulator/grayscale.framework" 2>/dev/null || true
codesign --remove-signature "$RELEASE_BUILD_DIR/grayscale.xcframework" 2>/dev/null || true
codesign --force --deep --sign - "$RELEASE_BUILD_DIR/grayscale.xcframework"

# Create zip archives
cd "$RELEASE_BUILD_DIR"
if [ -d "zip" ]; then
    rm -rf zip
fi
mkdir zip

zip -r zip/App.xcframework.zip App.xcframework
zip -r zip/Flutter.xcframework.zip Flutter.xcframework
zip -r zip/FlutterPluginRegistrant.xcframework.zip FlutterPluginRegistrant.xcframework
zip -r zip/grayscale.xcframework.zip grayscale.xcframework
zip -r zip/NativeGrayscaleSDK.xcframework.zip NativeGrayscaleSDK.xcframework

# Compute checksums
cd "$RELEASE_BUILD_DIR/zip"
echo ""
echo "RELEASE checksum of App.xcframework.zip"
swift package compute-checksum App.xcframework.zip

echo "RELEASE checksum of Flutter.xcframework.zip"
swift package compute-checksum Flutter.xcframework.zip

echo "RELEASE checksum of FlutterPluginRegistrant.xcframework.zip"
swift package compute-checksum FlutterPluginRegistrant.xcframework.zip

echo "RELEASE checksum of grayscale.xcframework.zip"
swift package compute-checksum grayscale.xcframework.zip

echo "RELEASE checksum of NativeGrayscaleSDK.xcframework.zip"
swift package compute-checksum NativeGrayscaleSDK.xcframework.zip

# Recreate native app symlinks
cd "$NATIVE_APP_DIR"
ln -sf "$SDK_DIR/ios/NativeGrayscaleSDK" NativeGrayscaleSDK
ln -sf "$SDK_DIR/ios/NativeGrayscaleSDK.xcodeproj" NativeGrayscaleSDK.xcodeproj

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo ""
echo "✅ Build finished in $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec."

