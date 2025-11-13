//
//  LogDispatcher.swift
//  NativeGrayscaleSDK
//
//  Created by younggi.lee
//

import Foundation

internal class LogDispatcher {
  static let shared = LogDispatcher()
  
  internal var logInterceptor: FILogInterceptor?
  private init() {}
  
  func onLogMessage(_ message: String, priority: String) {
    onLogMessages([[
      "text": message,
      "priority": priority
    ]])
  }
  
  func onLogMessages(_ logMessages: [[String: Any]]) {
    guard let logInterceptor = self.logInterceptor,
          logMessages.count > 0 else {
      return
    }
    let minimumLevel = logInterceptor.minimumLogLevel
    for data in logMessages {
      guard let message = data["text"] as? String,
            let priority = data["priority"] as? String,
            let level = FILogLevel(rawValue: priority) else {
        continue
      }
      // 단순화: 로그 레벨이 minimumLogLevel 이상이면 출력
      if shouldLog(level: level, minimumLevel: minimumLevel) {
        logInterceptor.onLogMessage(message, level: level)
      }
    }
  }
  
  /// 로그 레벨 비교: level이 minimumLevel 이상이면 true
  private func shouldLog(level: FILogLevel, minimumLevel: FILogLevel) -> Bool {
    if minimumLevel == .none {
      return false
    }
    // Comparable 프로토콜을 사용하여 간단하게 비교
    return level >= minimumLevel
  }
}

internal class Loggable {
  func print(_ message: String, priority: String = "debug") {
    LogDispatcher.shared.onLogMessage(message, priority: priority)
  }
  
  func print(_ error: Error, priority: String = "error") {
    LogDispatcher.shared.onLogMessage("\(error)", priority: priority)
  }
}
