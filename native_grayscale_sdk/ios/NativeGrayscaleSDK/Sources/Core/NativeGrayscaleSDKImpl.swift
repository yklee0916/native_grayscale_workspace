//
//  NativeGrayscaleSDKImpl.swift
//  NativeGrayscaleSDK
//
//  Created by younggi.lee
//

import Flutter
import FlutterPluginRegistrant
import Foundation

internal class NativeGrayscaleSDKImpl: Loggable {
  
  private var dispatchQueue: DispatchQueue?
  
  private(set) var flutterEngine: FlutterEngine?
  private var imageChannel: FlutterMethodChannel?
  private var logChannel: FlutterMethodChannel?
  private let identifier = "com.sktelecom.native.grayscale.sdk"
  
  private var minimumLogLevel: FILogLevel?
  
  override init() {
    super.init()
  }
  
  func getVersion() -> String {
    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
      return version
    }
    return "1.0.0"
  }
  
  func initialize(completion: @escaping (Bool) -> Void) {
    Task { @MainActor in
      self.dispatchQueue = DispatchQueue(label: "\(identifier)/engine", qos: DispatchQoS.userInteractive)
      
      if self.flutterEngine == nil {
        self.flutterEngine = FlutterEngine(name: "io.flutter", project: nil)
        self.flutterEngine?.run(withEntrypoint: nil)
      }
      guard let flutterEngine = self.flutterEngine else { return }
      
      // 플러그인 등록 (Grayscale 플러그인 등)
      GeneratedPluginRegistrant.register(with: flutterEngine)
      
      // Image channel (grayscale requests)
      imageChannel = FlutterMethodChannel(
        name: "\(identifier)/image",
        binaryMessenger: flutterEngine.binaryMessenger
      )
      
      // Log channel (log interceptor, minimum log level, message forwarding)
      logChannel = FlutterMethodChannel(
        name: "\(identifier)/log",
        binaryMessenger: flutterEngine.binaryMessenger
      )
      
      // 로그 메시지 핸들러 설정 (log channel)
      logChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        guard let self = self else { return }
        
        switch(call.method) {
        case "onLogMessage":
          if let args = call.arguments as? [String: Any],
             let logMessages = args["logMessages"] as? [[String: Any]],
             logMessages.count > 0 {
            LogDispatcher.shared.onLogMessages(logMessages)
          }
          break
        default:
          self.print("Unrecognized method name: \(call.method)")
          break
        }
      })
      
      completion(true)
    }
  }
  
  func convertToGrayscale(
    imagePath: String,
    completion: @escaping (Result<String, NativeGrayscaleSDKError>) -> Void
  ) {
    // Method Channel을 통해 Dart로 요청
    guard let methodChannel = self.imageChannel else {
      let error = NativeGrayscaleSDKError(
        code: .methodChannelNotInitialized
      )
      completion(.failure(error))
      return
    }
    
    dispatchQueue?.async { [weak self] in
      guard let self = self else {
        let error = NativeGrayscaleSDKError(
          code: .unknownError,
          message: "Internal error: self is nil"
        )
        completion(.failure(error))
        return
      }
      
      // 파일 존재 확인
      let srcURL = URL(fileURLWithPath: imagePath)
      guard FileManager.default.fileExists(atPath: srcURL.path) else {
        let error = NativeGrayscaleSDKError(
          code: .imageFileNotFound,
          message: "Image file does not exist at path: \(imagePath)"
        )
        completion(.failure(error))
        return
      }
      
      // Dart로 method channel을 통해 요청
      let arguments: [String: Any] = ["imagePath": imagePath]
      
      methodChannel.invokeMethod("convertToGrayscale", arguments: arguments) { [weak self] (result: Any?) in
        guard let _ = self else {
          let error = NativeGrayscaleSDKError(
            code: .unknownError,
            message: "Internal error: self is nil"
          )
          completion(.failure(error))
          return
        }
        
        // FlutterError 처리
        if let flutterError = result as? FlutterError {
          if let error = NativeGrayscaleSDKError.fromFlutterError(flutterError) {
            completion(.failure(error))
          } else {
            let error = NativeGrayscaleSDKError(
              code: .unknownError,
              message: flutterError.message ?? "Unknown error"
            )
            completion(.failure(error))
          }
          return
        }
        
        // 성공 응답 처리
        if let resultMap = result as? [String: Any],
           let resultPath = resultMap["resultPath"] as? String {
          completion(.success(resultPath))
        } else {
          let error = NativeGrayscaleSDKError(
            code: .invalidResponse
          )
          completion(.failure(error))
        }
      }
    }
  }
  
  func setMinimumLogLevel(_ logLevel: FILogLevel) {
    Task { @MainActor in
      let args: Dictionary<String, Any> = [
        "minimumLogLevel": logLevel.rawValue
      ]
      logChannel?.invokeMethod("setMinimumLogLevel", arguments: args)
    }
  }
  
  func setLogInterceptor(_ interceptor: FILogInterceptor?) {
    Task { @MainActor in
      LogDispatcher.shared.logInterceptor = interceptor
      var arguments: [String: Any] = [
        "enabled": interceptor != nil ? true : false
      ]
      if let interceptor = interceptor {
        arguments["minimumLogLevel"] = interceptor.minimumLogLevel.rawValue
      }
      logChannel?.invokeMethod("setLogInterceptor", arguments: arguments)
    }
  }
}

