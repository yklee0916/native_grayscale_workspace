//
//  ContentView.swift
//  GrayscaleSampleApp
//
//  Created by younggi.lee
//

import SwiftUI
import PhotosUI

struct ContentView: View {
  @ObservedObject private var viewModel = GrayscaleViewModel.shared
  @State private var showImagePicker = false
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Grayscale Image Converter")
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding()
      
      HStack(spacing: 20) {
        // 좌측: 원본 이미지
        VStack {
          Text("원본")
            .font(.headline)
            .padding(.bottom, 8)
          
          if let originalImage = viewModel.originalImage {
            Image(uiImage: originalImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: .infinity, maxHeight: 300)
              .border(Color.gray, width: 1)
          } else {
            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .frame(maxWidth: .infinity, maxHeight: 300)
              .overlay(
                Text("이미지를 선택하세요")
                  .foregroundColor(.gray)
              )
          }
        }
        .frame(maxWidth: .infinity)
        
        // 우측: 변환된 grayscale 이미지
        VStack {
          Text("변환 후")
            .font(.headline)
            .padding(.bottom, 8)
          
          if let grayscaleImage = viewModel.grayscaleImage {
            Image(uiImage: grayscaleImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: .infinity, maxHeight: 300)
              .border(Color.gray, width: 1)
          } else {
            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .frame(maxWidth: .infinity, maxHeight: 300)
              .overlay(
                Text("변환된 이미지가\n여기에 표시됩니다")
                  .foregroundColor(.gray)
                  .multilineTextAlignment(.center)
              )
          }
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.horizontal)
      
      // 에러 메시지
      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .padding()
      }
      
      // 버튼들
      HStack(spacing: 20) {
        Button(action: {
          viewModel.pickImage()
          showImagePicker = true
        }) {
          Text("이미지 선택")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(viewModel.isConverting)
        
        Button(action: {
          viewModel.convertToGrayscale()
        }) {
          if viewModel.isConverting {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.gray)
              .cornerRadius(10)
          } else {
            Text("Grayscale 변환")
              .frame(maxWidth: .infinity)
              .padding()
              .background(viewModel.selectedImagePath != nil ? Color.green : Color.gray)
              .foregroundColor(.white)
              .cornerRadius(10)
          }
        }
        .disabled(viewModel.selectedImagePath == nil || viewModel.isConverting)
      }
      .padding(.horizontal)
      
      Spacer()
    }
    .sheet(isPresented: $showImagePicker) {
      ImagePicker(viewModel: viewModel)
    }
  }
}

// 이미지 선택을 위한 Picker
struct ImagePicker: UIViewControllerRepresentable {
  @ObservedObject var viewModel: GrayscaleViewModel
  @Environment(\.presentationMode) var presentationMode
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .photoLibrary
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let uiImage = info[.originalImage] as? UIImage {
        // 이미지를 임시 디렉토리에 저장
        var imagePath: String?
        if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
          let tempDir = FileManager.default.temporaryDirectory
          let fileName = "\(UUID().uuidString).jpg"
          let fileURL = tempDir.appendingPathComponent(fileName)
          
          do {
            try imageData.write(to: fileURL)
            imagePath = fileURL.path
          } catch {
            print("Failed to save image: \(error)")
            parent.viewModel.setError("이미지 저장 실패: \(error.localizedDescription)")
          }
        }
        
        // ViewModel에 이미지 설정
        parent.viewModel.setOriginalImage(uiImage, imagePath: imagePath)
      }
      
      parent.presentationMode.wrappedValue.dismiss()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.presentationMode.wrappedValue.dismiss()
    }
  }
}

#Preview {
  ContentView()
}
