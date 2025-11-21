//
//  ConsoleLogListener.swift
//  NativeGrayscaleSample
//
//  Created by younggi.lee
//

import Foundation
import NativeGrayscaleSDK

/// SDK 로그를 콘솔에 출력하는 간단한 인터셉터
class ConsoleLogListener: FILogInterceptor {
  static let shared = ConsoleLogListener()
  private init() {}
  
  var minimumLogLevel: FILogLevel {
    return .info
  }
  
  func appLogMessage(_ message: String, level: FILogLevel, f: String = #file, l: Int = #line) {
    var log = ""
    if let filename = f.split(separator: "/").last {
      log = "\(log)[\(filename):\(l)]"
    }
    log = "\(log) \(message)"
    printMessage(log, level: level, tag: "APP")
  }
  
  func onLogMessage(_ message: String, level: FILogLevel) {
    printMessage(message, level: level, tag: "SDK")
  }
  
  private func printMessage(_ message: String, level: FILogLevel, tag: String) {
    let time = Date().timeString()
    let fullLogMessage = "[\(time)][\(tag)][\(level.rawValue)]\(message)"
    
    // 콘솔에 출력
    print(fullLogMessage)
  }
}

private extension Date {
  func timeString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "YY/MM/dd HH:mm:ss.SSS"
    return dateFormatter.string(from: self)
  }
}

extension ObservableObject {
  func print(_ message: String, level: FILogLevel = .debug, f: String = #file, l: Int = #line) {
    ConsoleLogListener.shared.appLogMessage(message, level: level, f: f, l: l)
  }
  func print(_ error: Error, level: FILogLevel = .debug, f: String = #file, l: Int = #line) {
    ConsoleLogListener.shared.appLogMessage("\(error)", level: level, f: f, l: l)
  }
}

extension NSObject {
  func print(_ message: String, level: FILogLevel = .debug, f: String = #file, l: Int = #line) {
    ConsoleLogListener.shared.appLogMessage(message, level: level, f: f, l: l)
  }
  func print(_ error: Error, level: FILogLevel = .debug, f: String = #file, l: Int = #line) {
    ConsoleLogListener.shared.appLogMessage("\(error)", level: level, f: f, l: l)
  }
}

