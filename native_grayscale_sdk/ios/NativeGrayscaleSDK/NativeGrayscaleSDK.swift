//
//  NativeGrayscaleSDK.swift
//  NativeGrayscaleSDK
//
//  Created by younggi.lee
//

import Flutter
import Foundation

/// NativeGrayscaleSDK SDK의 메인 인스턴스
///
/// 이미지 grayscale 변환 기능을 제공하는 SDK입니다.
public class GrayscaleSDK {
  /// SDK 인스턴스로 Singleton 객체만을 지원함
  public static let shared = GrayscaleSDK()
  
  private var instance = NativeGrayscaleSDKImpl()
  
  private init() {
  }
  
  /// SDK의 버전 정보를 반환한다.
  public func getVersion() -> String {
    return instance.getVersion()
  }
  
  /// Flutter Engine 및 SDK 내 인스턴스 초기화
  /// - Parameters:
  ///   - completion: 초기화 완료시 반환
  public func initialize(completion: @escaping (Bool) -> Void) {
    instance.initialize(completion: completion)
  }
  
  /// Flutter Engine 및 SDK 내 인스턴스 초기화 (Asynchronous)
  public func initialize() async throws -> Bool {
    return try await withCheckedThrowingContinuation { continuation in
      initialize() { (result: Bool) in
        continuation.resume(returning: result)
      }
    }
  }
  
  /// 이미지를 grayscale로 변환한다.
  /// - Parameters:
  ///   - imagePath: 변환할 이미지 파일 경로
  ///   - completion: 변환 완료시 결과를 반환 (성공시 경로, 실패시 에러)
  public func convertToGrayscale(
    imagePath: String,
    completion: @escaping (Result<String, NativeGrayscaleSDKError>) -> Void
  ) {
    instance.convertToGrayscale(imagePath: imagePath, completion: completion)
  }
  
  /// 이미지를 grayscale로 변환한다. (Asynchronous)
  /// - Parameters:
  ///   - imagePath: 변환할 이미지 파일 경로
  /// - Returns: 변환된 이미지 파일 경로
  /// - Throws: NativeGrayscaleSDKError 변환 실패시
  public func convertToGrayscale(imagePath: String) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      convertToGrayscale(imagePath: imagePath) { result in
        switch result {
        case .success(let path):
          continuation.resume(returning: path)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// ``initialize()`` 이후 획득 가능한 Flutter 엔진 인스턴스
  public var flutterEngine: FlutterEngine? {
    return instance.flutterEngine
  }
  
  /// 로그 최소 레벨을 설정한다.
  public func setMinimumLogLevel(_ logLevel: FILogLevel) {
    instance.setMinimumLogLevel(logLevel)
  }
  
  /// SDK 내부 로그 출력 메시지들 획득 가능한 Interceptor 를 설정 한다.
  ///
  /// 로그를 출력하고 싶지 않은 경우 Interceptor 를 nil 로 설정하여 해지한다.
  public func setLogInterceptor(_ interceptor: FILogInterceptor?) {
    instance.setLogInterceptor(interceptor)
  }
}

