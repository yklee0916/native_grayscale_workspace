# Native Grayscale SDK

A bridge SDK that enables native iOS/macOS applications to use Flutter plugins (`flutter_grayscale`, `flutter_log`) without requiring a full Flutter app.

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yklee0916/native_grayscale_sdk.git", from: "1.0.0")
]
```

Or add it via Xcode:
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/yklee0916/native_grayscale_sdk.git`
3. Select version `1.0.0` or later
4. Click Add Package

## Usage

### Basic Setup

```swift
import NativeGrayscaleSDK

// 1. Initialize SDK
GrayscaleSDK.shared.initialize { success in
    guard success else {
        print("SDK initialization failed")
        return
    }
    
    // 2. Set up logging (optional)
    GrayscaleSDK.shared.setLogInterceptor(ConsoleLogListener())
    GrayscaleSDK.shared.setMinimumLogLevel(.info)
    
    // SDK is ready to use
}
```

### Convert Image to Grayscale

#### Using Completion Handler

```swift
GrayscaleSDK.shared.convertToGrayscale(imagePath: "/path/to/image.jpg") { result in
    switch result {
    case .success(let outputPath):
        print("Converted image saved at: \(outputPath)")
        // Use the converted image
    case .failure(let error):
        print("Error [\(error.code)]: \(error.message)")
    }
}
```

#### Using Async/Await

```swift
Task {
    do {
        // Initialize SDK
        let success = try await GrayscaleSDK.shared.initialize()
        guard success else {
            print("SDK initialization failed")
            return
        }
        
        // Set up logging (optional)
        GrayscaleSDK.shared.setLogInterceptor(ConsoleLogListener())
        GrayscaleSDK.shared.setMinimumLogLevel(.info)
        
        // Convert image
        let outputPath = try await GrayscaleSDK.shared.convertToGrayscale(imagePath: "/path/to/image.jpg")
        print("Converted image saved at: \(outputPath)")
    } catch {
        print("Error: \(error)")
    }
}
```

### Logging

Create a custom log listener to receive SDK logs:

```swift
class ConsoleLogListener: FILogInterceptor {
    var minimumLogLevel: FILogLevel {
        return .info
    }
    
    let tag: String = "SDK"
    
    func onLogMessage(_ message: String, level: FILogLevel) {
        print("[\(tag)][\(level.rawValue)] \(message)")
    }
}

// Set the log interceptor
GrayscaleSDK.shared.setLogInterceptor(ConsoleLogListener())
GrayscaleSDK.shared.setMinimumLogLevel(.info)
```

### Error Handling

Errors are returned as `NativeGrayscaleSDKError` with error codes:

- **1000s**: Method channel errors
- **1100s**: Image processing errors
- **1200s**: Log management errors
- **2000s**: SDK initialization errors
- **9000s**: Unknown errors

```swift
do {
    let outputPath = try await GrayscaleSDK.shared.convertToGrayscale(imagePath: imagePath)
} catch let error as NativeGrayscaleSDKError {
    print("Error [\(error.code)]: \(error.message)")
} catch {
    print("Unknown error: \(error)")
}
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Xcode 14.0+
- Swift 5.0+

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Younggi Lee
