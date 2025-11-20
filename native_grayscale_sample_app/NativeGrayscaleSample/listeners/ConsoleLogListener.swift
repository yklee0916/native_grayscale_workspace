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
  
  var minimumLogLevel: FILogLevel {
    return .info
  }
  
  let tag: String = "SDK"
  
  func onLogMessage(_ message: String, level: FILogLevel) {
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


