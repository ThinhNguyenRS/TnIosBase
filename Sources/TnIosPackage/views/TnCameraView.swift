//
//  CaptureImageView.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 9/9/21.
//

import Foundation
import SwiftUI
import UIKit

struct TnCameraView {
    @Environment(\.presentationMode) var presentationMode
    let handler: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: TnCameraView

        init(_ parent: TnCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            let livePhoto = info[UIImagePickerController.InfoKey.livePhoto] as? UIImage
//            let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage

            if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//                let cgImage = originalImage.cgImage
                
                self.parent.handler(originalImage)
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.parent.presentationMode.wrappedValue.dismiss()
            
            
        }
    }
}

extension TnCameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<TnCameraView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        picker.showsCameraControls = true
        picker.allowsEditing = false

        //        picker.cameraViewTransform = CGAffineTransform.identity.scaledBy(x: -1, y: 1)
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<TnCameraView>) {
    }
}

