//
//  TnOrientation.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/23/24.
//

import Foundation
import UIKit
import Combine
import SwiftUI

public class TnOrientationManager: ObservableObject {
    @Published public var type: UIDeviceOrientation = .unknown
    
    private var cancellables: Set<AnyCancellable> = []
    
    private init() {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene as? UIWindowScene else { return }
        
        let orientation = sceneDelegate.interfaceOrientation
        
        switch orientation {
        case .portrait: type = .portrait
        case .portraitUpsideDown: type = .portraitUpsideDown
        case .landscapeLeft: type = .landscapeLeft
        case .landscapeRight: type = .landscapeRight
            
        default: type = .unknown
        }
        
        NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink() { [weak self] _ in
                self?.type = UIDevice.current.orientation
            }
            .store(in: &cancellables)
    }
    
    public static let shared = TnOrientationManager()
}

@propertyWrapper struct TnOrientation: DynamicProperty {
    @StateObject private var manager = TnOrientationManager.shared
    
    var wrappedValue: UIDeviceOrientation {
        manager.type
    }
}

