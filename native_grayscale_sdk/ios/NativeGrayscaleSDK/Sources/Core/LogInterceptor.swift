//
//  LogInterceptor.swift
//  NativeGrayscaleSDK
//
//  Created by younggi.lee
//

/// SDK 내부 로그 출력 메시지들의 Priority
public enum FILogLevel: String, Codable, Comparable {
  case verbose = "V"
  case debug = "D"
  case info = "I"
  case warning = "W"
  case error = "E"
  case none = "N"
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    self = FILogLevel(rawValue: rawValue) ?? .none
  }
  
  /// 로그 레벨 비교를 위한 순서
  private var order: Int {
    switch self {
    case .none: return 0
    case .error: return 1
    case .warning: return 2
    case .info: return 3
    case .debug: return 4
    case .verbose: return 5
    }
  }
  
  public static func < (lhs: FILogLevel, rhs: FILogLevel) -> Bool {
    return lhs.order < rhs.order
  }
}

/// SDK 내부 로그 메시지를 확인 할 수 있는 Interceptor
/// ``setLogInterceptor(_ interceptor:)`` 를 통해 설정 가능 하다.
public protocol FILogInterceptor {
  /// LogLevel filter 를 위한 level 을 반환한다.
  var minimumLogLevel: FILogLevel { get }
  
  /// SDK 내부 로그 메시지 및 LogLevel 에 대하여 전달 받는다.
  func onLogMessage(_ message: String, level: FILogLevel)
}
