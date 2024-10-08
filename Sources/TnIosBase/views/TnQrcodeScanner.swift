//
//  CodeScannerView.swift
//
//  Created by Paul Hudson on 10/12/2019.
//  Copyright © 2019 Paul Hudson. All rights reserved.
//

import AVFoundation
import SwiftUI

/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `codeTypes` to be an array of things to scan for, e.g. `[.qr]`, and set `completion` to
/// a closure that will be called when scanning has finished. This will be sent the string that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
public struct CodeScannerView: UIViewControllerRepresentable {
    public enum ScanError: Error {
        case badInput, badOutput
    }
    
    public enum ScanMode {
        case once, oncePerCode, continuous
    }

    public class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CodeScannerView
        var codesFound: Set<String>
        var isFinishScanning = false
        var lastTime = Date(timeIntervalSince1970: 0)

        init(parent: CodeScannerView) {
            self.parent = parent
            self.codesFound = Set<String>()
        }

        public func reset()
        {
            self.codesFound = Set<String>()
            self.isFinishScanning = false
            self.lastTime = Date(timeIntervalSince1970: 0)
        }

        public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard isFinishScanning == false else { return }

                switch self.parent.scanMode {
                case .once:
                    found(code: stringValue)
                    // make sure we only trigger scan once per use
                    isFinishScanning = true
                case .oncePerCode:
                    if !codesFound.contains(stringValue) {
                        codesFound.insert(stringValue)
                        found(code: stringValue)
                    }
                case .continuous:
                    if isPastScanInterval() {
                        found(code: stringValue)
                    }
                }
            }
        }

        func isPastScanInterval() -> Bool {
            return Date().timeIntervalSince(lastTime) >= self.parent.scanInterval
        }
        
        func found(code: String) {
            lastTime = Date()
            parent.completion(.success(code))
        }

        func didFail(reason: ScanError) {
            parent.completion(.failure(reason))
        }
    }

    public class ScannerViewController: UIViewController {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate: ScannerCoordinator?
        let videoCaptureDevice = AVCaptureDevice.default(for: .video)

        private let showViewfinder: Bool

        private lazy var viewFinder: UIImageView? = {
            guard let image = UIImage(named: "viewfinder") else {
                return nil
            }

            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()

        public init(showViewfinder: Bool) {
            self.showViewfinder = showViewfinder
            super.init(nibName: nil, bundle: nil)
        }

        public required init?(coder: NSCoder) {
            self.showViewfinder = false
            super.init(coder: coder)
        }

        override public func viewDidLoad() {
            super.viewDidLoad()


            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(updateOrientation),
                                                   name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
                                                   object: nil)

            view.backgroundColor = UIColor.black
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = videoCaptureDevice else {
                return
            }

            guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                delegate?.didFail(reason: .badInput)
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = delegate?.parent.codeTypes
            } else {
                delegate?.didFail(reason: .badOutput)
                return
            }
        }

        override public func viewWillLayoutSubviews() {
            previewLayer?.frame = view.layer.bounds
        }

        @objc func updateOrientation() {
            guard let orientation = view.window?.windowScene?.interfaceOrientation else { return }
            guard let connection = captureSession.connections.last, connection.isVideoOrientationSupported else { return }
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
        }

        override public func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            updateOrientation()
        }

        override public func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            if previewLayer == nil {
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            }
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            addviewfinder()

            delegate?.reset()

            if (captureSession?.isRunning == false) {
                captureSession.startRunning()
            }
        }

        private func addviewfinder() {
            guard showViewfinder, let imageView = viewFinder else { return }
            
            view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 200),
                imageView.heightAnchor.constraint(equalToConstant: 200),
            ])
        }

        override public func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)

            if (captureSession?.isRunning == true) {
                captureSession.stopRunning()
            }

            NotificationCenter.default.removeObserver(self)
        }

        override public var prefersStatusBarHidden: Bool {
            return true
        }

        override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .all
        }
        
        /** Touch the screen for autofocus */
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard touches.first?.view == view,
                  let touchPoint = touches.first,
                  let device = videoCaptureDevice
            else { return }
            
            let videoView = view
            let screenSize = videoView!.bounds.size
            let xPoint = touchPoint.location(in: videoView).y / screenSize.height
            let yPoint = 1.0 - touchPoint.location(in: videoView).x / screenSize.width
            let focusPoint = CGPoint(x: xPoint, y: yPoint)
            
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            
            // Focus to the correct point, make continiuous focus and exposure so the point stays sharp when moving the device closer
            device.focusPointOfInterest = focusPoint
            device.focusMode = .continuousAutoFocus
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.unlockForConfiguration()
        }
    }

    public let codeTypes: [AVMetadataObject.ObjectType]
    public let scanMode: ScanMode
    public let scanInterval: Double
    public let showViewfinder: Bool
    public var simulatedData = ""
    public var completion: (Result<String, ScanError>) -> Void

    public init(codeTypes: [AVMetadataObject.ObjectType], scanMode: ScanMode = .once, showViewfinder: Bool = true, scanInterval: Double = 2.0, simulatedData: String = "", completion: @escaping (Result<String, ScanError>) -> Void) {
        self.codeTypes = codeTypes
        self.scanMode = scanMode
        self.showViewfinder = showViewfinder
        self.scanInterval = scanInterval
        self.simulatedData = simulatedData
        self.completion = completion
    }

    public func makeCoordinator() -> ScannerCoordinator {
        return ScannerCoordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController(showViewfinder: showViewfinder)
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {

    }
}
