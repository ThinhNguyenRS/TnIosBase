//
//  TnPhotoPicker.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 9/9/21.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI

struct TnPhotoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    let configuration: PHPickerConfiguration
    let handler: (UIImage) -> Void
    
    init(configuration: PHPickerConfiguration, handler: @escaping (UIImage) -> Void) {
        self.configuration = configuration
        self.handler = handler
    }
    
    init(filter: PHPickerFilter = .any(of: [.images, .livePhotos]), limit: Int = 10, handler: @escaping (UIImage) -> Void) {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = filter
        config.selectionLimit = limit
        
        self.init(configuration: config, handler: handler)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Use a Coordinator to act as your PHPickerViewControllerDelegate
    class Coordinator: PHPickerViewControllerDelegate {
        private let parent: TnPhotoPicker

        init(_ parent: TnPhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { selectedImage, error in
                    if let uiImage = selectedImage as? UIImage {
                        self.parent.handler(uiImage)
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
