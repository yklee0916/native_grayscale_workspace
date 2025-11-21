//
//  GrayscaleViewModel.swift
//  NativeGrayscaleSample
//
//  Created by younggi.lee
//

import SwiftUI
import Combine
import PhotosUI
import NativeGrayscaleSDK

@MainActor
class GrayscaleViewModel: ObservableObject {
  static let shared = GrayscaleViewModel()
  
  @Published var originalImage: UIImage?
  @Published var grayscaleImage: UIImage?
  @Published var selectedImagePath: String?
  @Published var isConverting = false
  @Published var errorMessage: String?
  @Published var isSDKInitialized = false
  
  private var cancellables = Set<AnyCancellable>()
  
  private init() {
  }
  
  func initializeSDK() {
    // SDK 버전 확인
    print("GrayscaleSDK getVersion: \(GrayscaleSDK.shared.getVersion())")
    
    Task {
      do {
        // SDK 초기화
        let initializeResult = try await GrayscaleSDK.shared.initialize()
        print("GrayscaleSDK initialize: \(String(describing: initializeResult))")
        
        if !initializeResult {
          errorMessage = "SDK 초기화 실패"
          return
        }
        // SDK 로그 인터셉터 설정
        GrayscaleSDK.shared.setLogInterceptor(ConsoleLogListener.shared)
        
        isSDKInitialized = true
      } catch {
        errorMessage = "SDK 초기화 오류: \(error.localizedDescription)"
        print("SDK 초기화 오류: \(error.localizedDescription)")
      }
    }
  }
  
  func pickImage() {
    resetSelection()
    // 이미지 선택은 ContentView에서 sheet를 통해 처리
    // ViewModel은 이미지 선택 완료 후 setOriginalImage를 호출받음
  }
  
  func setOriginalImage(_ image: UIImage?, imagePath: String?) {
    originalImage = image
    selectedImagePath = imagePath
    grayscaleImage = nil
    errorMessage = nil
  }
  
  func convertToGrayscale() {
    guard isSDKInitialized else {
      errorMessage = "SDK가 초기화되지 않았습니다"
      return
    }
    guard let imagePath = selectedImagePath else {
      errorMessage = "이미지를 선택해주세요"
      return
    }
    isConverting = true
    errorMessage = nil
    
    Task { @MainActor in
      do {
        let resultPath = try await GrayscaleSDK.shared.convertToGrayscale(imagePath: imagePath)
        
        // 변환된 이미지 로드
        if let imageData = try? Data(contentsOf: URL(fileURLWithPath: resultPath)),
           let image = UIImage(data: imageData) {
          await MainActor.run {
            grayscaleImage = image
            isConverting = false
          }
        } else {
          await MainActor.run {
            errorMessage = "변환된 이미지를 로드할 수 없습니다"
            isConverting = false
          }
        }
      } catch let error as NativeGrayscaleSDKError {
        await MainActor.run {
          errorMessage = "변환 실패 [코드: \(error.code)]: \(error.message)"
          isConverting = false
        }
      } catch {
        await MainActor.run {
          errorMessage = "변환 실패: \(error.localizedDescription)"
          isConverting = false
        }
      }
    }
  }
  
  func resetSelection() {
    originalImage = nil
    grayscaleImage = nil
    selectedImagePath = nil
    errorMessage = nil
    isConverting = false
  }
  
  func setError(_ error: String?) {
    errorMessage = error
  }
}

