# Native Grayscale Workspace

This workspace contains the complete source code for the Native Grayscale SDK and sample application.

## Structure

```
native_grayscale_workspace/
├── native_grayscale_sdk/          # SDK source code
│   ├── ios/                       # iOS SDK implementation
│   └── flutter/                   # Flutter module
└── native_grayscale_sample_app/   # Sample iOS app
```

## Projects

### native_grayscale_sdk

The SDK source code that bridges Flutter plugins to native iOS/macOS applications.

- **iOS SDK**: Swift implementation with Flutter Engine integration
- **Flutter Module**: Dart code that handles Method Channels and routes to Flutter plugins
- **Build Scripts**: `setup_ios.sh` and `build_xcframework_release.sh`

For more information, see the [published SDK repository](https://github.com/yklee0916/native_grayscale_sdk).

### native_grayscale_sample_app

A sample iOS application demonstrating how to use the Native Grayscale SDK via Swift Package Manager.

- **Architecture**: MVVM pattern
- **SDK Integration**: Uses NativeGrayscaleSDK via SPM
- **Features**: Image selection and grayscale conversion

For more information, see the [published sample app repository](https://github.com/yklee0916/native_grayscale_sample_app).

## Building

### SDK

1. Setup iOS environment:
```bash
cd native_grayscale_sdk
./setup_ios.sh
```

2. Build release xcframework:
```bash
./build_xcframework_release.sh
```

### Sample App

1. Open in Xcode:
```bash
cd native_grayscale_sample_app
open NativeGrayscaleSample.xcodeproj
```

2. Build and run in Xcode

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Younggi Lee

