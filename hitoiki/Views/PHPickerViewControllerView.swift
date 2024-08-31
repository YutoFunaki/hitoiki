//
//  PHPickerViewControllerView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/08/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers  // UTTypeを使うためのインポート

struct PHPickerViewControllerView: UIViewControllerRepresentable {
    @Binding var mediaItems: [UIImage?]
    @Binding var videoURLs: [URL?]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 4 // 最大4つのメディアを選択可能
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PHPickerViewControllerView
        
        init(_ parent: PHPickerViewControllerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for (index, result) in results.enumerated() {
                if index < parent.mediaItems.count {
                    let provider = result.itemProvider
                    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        provider.loadObject(ofClass: UIImage.self) { (image, error) in
                            DispatchQueue.main.async {
                                if let image = image as? UIImage {
                                    self.parent.mediaItems[index] = image
                                } else {
                                    print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                                }
                            }
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                            DispatchQueue.main.async {
                                if let url = url {
                                    self.parent.videoURLs[index] = url
                                } else {
                                    print("Failed to load video: \(error?.localizedDescription ?? "Unknown error")")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
