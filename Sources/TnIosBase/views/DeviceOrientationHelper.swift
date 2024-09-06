//
//  DeviceOrientationHelper.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/23/24.
//


import Foundation
import CoreMotion
import UIKit
import SwiftUI


public class DeviceMotionOrientationListener: ObservableObject {
    public static let shared = DeviceMotionOrientationListener() // Singleton is recommended because an app should create only a single instance of the CMMotionManager class.
    
    private let motionManager: CMMotionManager
    private let queue: OperationQueue
    
    typealias DeviceMotionOrientationHandler = (_ newOrientation: UIDeviceOrientation) -> Void
    private let motionLimit: Double = 0.6 // Smallers values makes it much sensitive to detect an orientation change. [0 to 1]
    private var handler: DeviceMotionOrientationHandler?

    @Published public var orientation: UIDeviceOrientation = .unknown
    @Published public var angle: Angle = .zero

    private init() {
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.2 // Specify an update interval in seconds, personally found this value provides a good UX
        queue = OperationQueue()
    }
    
    deinit {
        self.stop()
    }
    
    public func start() {
        if motionManager.isAccelerometerActive {
            return
        }

        handler = handler ?? { newOrientation in
            withAnimation {
                self.orientation = newOrientation

                switch self.orientation {
                case .portrait:
                    self.angle = Angle(degrees: 0)
                    break
                case .portraitUpsideDown:
                    self.angle = Angle(degrees: 180)
                    break
                case .landscapeLeft:
                    self.angle = Angle(degrees: -90)
                    break
                case .landscapeRight:
                    self.angle = Angle(degrees: 90)
                    break
                default:
                    break
                }
            }
        }

        //  Using main queue is not recommended. So create new operation queue and pass it to startAccelerometerUpdatesToQueue.
        //  Dispatch U/I code to main thread using dispach_async in the handler.
        
        motionManager.startAccelerometerUpdates(to: queue) { (data, error) in
            if let accelerometerData = data {
                var newOrientation: UIDeviceOrientation?
                
                if (accelerometerData.acceleration.y <= -self.motionLimit) {
                    newOrientation = .portrait
                }
                else if (accelerometerData.acceleration.y >= self.motionLimit) {
                    newOrientation = .portraitUpsideDown
                }
                else if (accelerometerData.acceleration.x <= -self.motionLimit) {
                    newOrientation = .landscapeLeft
                }
                else if (accelerometerData.acceleration.x >= self.motionLimit) {
                    newOrientation = .landscapeRight
                }

                if let newOrientation {
                    // Only if a different orientation is detect, execute handler
                    if newOrientation != self.orientation {
//                        TnLogger.debug("DeviceMotionOrientationListener", self.orientation.rawValue, newOrientation.rawValue)
                        DispatchQueue.main.async {
                            self.handler!(newOrientation)
                        }
                    }
                }
            }
        }
    }
    
    public func stop() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }
}
