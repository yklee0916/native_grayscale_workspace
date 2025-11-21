//
//  NativeGrayscaleSampleApp.swift
//  NativeGrayscaleSample
//
//  Created by younggi.lee on 11/10/25.
//

import SwiftUI
import Toasts

@main
struct MainApp: App {
  @UIApplicationDelegateAdaptor(MyAppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView().installToast(position: .bottom)
    }
  }
}

