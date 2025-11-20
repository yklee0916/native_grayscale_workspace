//
//  AppDelegate.swift
//  NativeGrayscaleSample
//
//  Created by younggi.lee
//

import UIKit

class MyAppDelegate: NSObject, UIApplicationDelegate {
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    GrayscaleViewModel.shared.initializeSDK()
    return true
  }
}

