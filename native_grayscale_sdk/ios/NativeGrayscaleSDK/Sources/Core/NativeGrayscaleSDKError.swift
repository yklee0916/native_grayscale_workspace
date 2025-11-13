//
//  NativeGrayscaleSDKError.swift
//  NativeGrayscaleSDK
//
//  Created by younggi.lee
//

import Flutter
import Foundation

/// SDK 에러 코드 정의
public enum NativeGrayscaleSDKErrorCode: Int {
  // Method Channel 관련 에러 (1000번대)
  case unknownMethod = 1001
  case methodCallError = 1002
  
  // Method Channel 초기화 관련 에러 (2000번대)
  case methodChannelNotInitialized = 2001
  case invalidResponse = 2003
  
  // Image 처리 관련 에러 (1100번대)
  case invalidArgument = 1101
  case imagePathRequired = 1102
  case conversionError = 1103
  case imageFileNotFound = 1104
  
  // Log 관련 에러 (1200번대)
  case setLogInterceptorError = 1201
  case setMinimumLogLevelError = 1202
  
  // 기타 에러 (9000번대)
  case unknownError = 9001
  
  /// 기본 에러 메시지
  var defaultMessage: String {
    switch self {
    case .unknownMethod:
      return "Unknown method"
    case .methodCallError:
      return "Error handling method call"
    case .methodChannelNotInitialized:
      return "Method channel is not initialized"
    case .invalidResponse:
      return "Invalid response from Dart"
    case .invalidArgument:
      return "Invalid argument"
    case .imagePathRequired:
      return "imagePath is required"
    case .conversionError:
      return "Failed to convert image to grayscale"
    case .imageFileNotFound:
      return "Image file does not exist at path"
    case .setLogInterceptorError:
      return "Failed to set log interceptor"
    case .setMinimumLogLevelError:
      return "Failed to set minimum log level"
    case .unknownError:
      return "Unknown error occurred"
    }
  }
}

/// NativeGrayscaleSDK SDK 에러 정의
///
/// Dart에서 전달된 에러를 파싱하고, 네이티브 앱으로 전달할 수 있는 형식으로 변환합니다.
public struct NativeGrayscaleSDKError: Error, LocalizedError {
  /// 에러 코드
  public let code: Int
  
  /// 에러 메시지
  public let message: String
  
  public init(code: Int, message: String) {
    self.code = code
    self.message = message
  }
  
  /// 에러 코드 enum을 사용하여 에러 생성
  public init(code: NativeGrayscaleSDKErrorCode, message: String? = nil) {
    self.code = code.rawValue
    self.message = message ?? code.defaultMessage
  }
  
  /// Dart에서 전달된 에러 딕셔너리를 파싱하여 NativeGrayscaleSDKError를 생성합니다.
  ///
  /// - Parameter errorDict: {'error': {'code': 1001, 'message': "error desc"}} 형식의 딕셔너리
  /// - Returns: 파싱된 NativeGrayscaleSDKError, 파싱 실패시 nil
  public static func fromDictionary(_ errorDict: [String: Any]?) -> NativeGrayscaleSDKError? {
    guard let errorDict = errorDict,
          let error = errorDict["error"] as? [String: Any],
          let code = error["code"] as? Int,
          let message = error["message"] as? String else {
      return nil
    }
    return NativeGrayscaleSDKError(code: code, message: message)
  }
  
  /// FlutterError의 details에서 NativeGrayscaleSDKError를 추출합니다.
  ///
  /// - Parameter flutterError: FlutterError 인스턴스
  /// - Returns: 파싱된 NativeGrayscaleSDKError, 파싱 실패시 nil
  public static func fromFlutterError(_ flutterError: FlutterError) -> NativeGrayscaleSDKError? {
    if let details = flutterError.details as? [String: Any] {
      return fromDictionary(details)
    }
    // FlutterError의 message와 code를 사용하여 기본 에러 생성
    return NativeGrayscaleSDKError(
      code: .unknownError,
      message: flutterError.message ?? "Unknown error"
    )
  }
  
  public var errorDescription: String? {
    return message
  }
  
  public var failureReason: String? {
    return "Error code: \(code)"
  }
}
