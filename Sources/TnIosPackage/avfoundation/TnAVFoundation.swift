//
//  AVCaptureConnectionExt.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/15/24.
//

import Foundation
import AVFoundation

extension AVCaptureConnection {
//    func setRotationAngle(_ v: CGFloat) {
//        if self.isVideoRotationAngleSupported(v) {
//            self.videoRotationAngle = v
//        }
//    }
    
    
    public var orientation: TnCameraOrientation {
        get {
            if #available(iOS 17.0, *) {
                .fromAngle(self.videoRotationAngle)
            } else {
                .fromVideoOrientation(self.videoOrientation)
            }
        }
        set {
            if #available(iOS 17.0, *) {
                let newAngle = newValue.toAngle()
                if (self.videoRotationAngle != newAngle) && self.isVideoRotationAngleSupported(newAngle) {
                    TnLogger.debug("AVCaptureConnection", "rotationAngle", self.videoRotationAngle, newAngle)
                    self.videoRotationAngle = newAngle
                }
            } else {
                self.videoOrientation = newValue.toVideoOrientation()
            }
        }
    }
}

extension AVCaptureOutput {
    public var orientation: TnCameraOrientation {
        get {
            self.connection(with: .video)?.orientation ?? .portrait
        }
        set {
            if let connection = self.connection(with: .video) {
                connection.orientation = newValue
            }
        }
    }
}

extension CMVideoDimensions: Hashable, Comparable {
    public static func < (lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        lhs.width < rhs.width
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
    
    public static func == (lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    public var description: String {
        "\(width)x\(height)"
    }
}
// MARK: AVCaptureDevice
extension AVCaptureDevice {
    public var deviceTypeDescription: String {
        self.deviceType.description
    }
    
    public func getDepthFormats(mediaSubTypes: [FourCharCode]) -> [AVCaptureDevice.Format] {
        self.activeFormat.getDepthFormats(mediaSubTypes: mediaSubTypes)
    }

    public func getDepthFormat(mediaSubTypes: [FourCharCode]) -> AVCaptureDevice.Format? {
        self.activeFormat.getDepthFormat(mediaSubTypes: mediaSubTypes)
    }
}

// MARK: AVCaptureDevice.Format
extension AVCaptureDevice.Format {
    public var isWideColorSupported: Bool {
        //        return [
        //            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        //            kCVPixelFormatType_32BGRA,
        //            kCVPixelFormatType_32BGRA,
        //            kCVPixelFormatType_32RGBA
        //        ].contains(self.rawValue)
        self.formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    }
    
    public var isDepthSupported: Bool {
        self.supportedDepthDataFormats.contains { v in
            v.formatDescription.mediaSubType.rawValue.isIn(
                kCVPixelFormatType_DepthFloat16,
                kCVPixelFormatType_DepthFloat32,
                kCVPixelFormatType_DisparityFloat16,
                kCVPixelFormatType_DisparityFloat32
            )
        }
    }
    
    public func getDepthFormats(mediaSubTypes: [FourCharCode]) -> [AVCaptureDevice.Format] {
        self.supportedDepthDataFormats.filter { format in
            let pixelFormatType = format.formatDescription.mediaSubType.rawValue
            return pixelFormatType.isIn(mediaSubTypes)
        }
    }

    public func getDepthFormat(mediaSubTypes: [FourCharCode]) -> AVCaptureDevice.Format? {
        self.getDepthFormats(mediaSubTypes: mediaSubTypes).last
    }
    
}

// MARK: AVCaptureSession.Preset
extension AVCaptureSession.Preset: TnEnum {
    public static var allCases: [Self] = [
        .photo,
        .high,
        .hd4K3840x2160,
        .hd1920x1080,
        .hd1280x720
    ]
    
    public static var allMap: [Self: String] = [
        .photo: "Photo 4:3",
        .high: "High",
        .hd4K3840x2160: "4K 16:9",
        .hd1920x1080: "FHD",
        .hd1280x720: "HD",
    ]
}

// MARK: AVCaptureDevice.Position
extension AVCaptureDevice.Position: TnEnum {
    public static var allCases: [Self] {
        [
            .back,
            .front,
        ]
    }
    
    public static var allMap: [Self: String] = [
        .back: "Back",
        .front: "Front",
    ]
}

extension AVCaptureDevice.Position {
    public var imageName: String {
        switch self {
        case .front: "camera.rotate.fill"
        case .back: "camera.rotate"
        default: ""
        }
    }
    
    public func toggle() -> Self {
        self == .front ? .back : .front
    }
}

// MARK: AVCaptureDevice.FlashMode
extension AVCaptureDevice.FlashMode: TnEnum {
    public static var allCases: [Self] = [
        .off,
        .on,
        .auto
    ]
    
    public static var allMap: [Self: String] = [
        .off: "Off",
        .on: "On",
        .auto: "Auto"
    ]
}

extension AVCaptureDevice.FlashMode {
    var imageName: String {
        switch self {
        case .off: "bolt.slash"
        case .on: "bolt"
        case .auto: "bolt.circle"
        default: ""
        }
    }
    
}

// MARK: torch
extension AVCaptureDevice.TorchMode: TnEnum {
    public static var allMap: [AVCaptureDevice.TorchMode: String] {
        [
            .off: "Off",
            .on: "On",
            .auto: "Auto"
        ]
    }

    public static var allCases: [AVCaptureDevice.TorchMode] {
        [
            .off,
            .on,
            .auto
        ]
    }
}

// MARK: AVCaptureDevice.DeviceType
extension AVCaptureDevice.DeviceType: TnEnum {
    public static var allCases: [Self] = [
        // depth cams
        .builtInLiDARDepthCamera,
        .builtInTrueDepthCamera,
        // single cams
        .builtInWideAngleCamera,
        .builtInUltraWideCamera,
        .builtInTelephotoCamera,
        // compose cams
//        .builtInDualCamera,
        .builtInDualWideCamera,
        .builtInTripleCamera,
    ]
    
    public static var allMap: [Self: String] = [
        .builtInDualCamera: "Dual",
        .builtInDualWideCamera: "Dual Wide",
        .builtInLiDARDepthCamera: "LiDAR",
        .builtInTelephotoCamera: "Tele",
        .builtInTripleCamera: "Triple",
        .builtInTrueDepthCamera: "Depth",
        .builtInWideAngleCamera: "Wide",
        .builtInUltraWideCamera: "Ultra",
    ]
}

// MARK: exposures
extension AVCaptureDevice.ExposureMode: TnEnum {
    public static var allCases: [AVCaptureDevice.ExposureMode] {
        [
            .locked,
            .autoExpose,
            .continuousAutoExposure,
            .custom
        ]
    }

    public static var allMap: [Self: String] = [
        .locked: "Locked",
        .autoExpose: "Auto",
        .continuousAutoExposure: "Continuous",
        .custom: "Custom"
    ]
}

extension AVCapturePhotoOutput.QualityPrioritization: TnEnum {
    public static var allCases: [Self] {
        [
            .speed,
            .balanced,
            .quality
        ]
    }
    
    public static var allMap: Dictionary<AVCapturePhotoOutput.QualityPrioritization, String> {
        [
            .speed: "Speed",
            .balanced: "Balanced",
            .quality: "Quality"
        ]
    }
}

extension AVCaptureDevice.FocusMode: TnEnum {
    public static var allCases: [Self] {
        [
            .locked,
            .autoFocus,
            .continuousAutoFocus
        ]
    }
    public static var allMap: Dictionary<Self, String> {
        [
            .locked: "Locked",
            .autoFocus: "Auto",
            .continuousAutoFocus: "Continuous"
        ]
    }
}
