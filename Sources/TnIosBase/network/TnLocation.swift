//
//  TnLocation.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/4/24.
//

import Foundation
import CoreLocation

public class TnLocation: NSObject, ObservableObject, TnLoggable {
    private let locationManager: CLLocationManager
    private var completion: ((CLLocation?) -> Void)? = nil
    
    @Published public private(set) var location: CLLocation? = nil

    public override init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        super.init()
        
        locationManager.delegate = self
    }
    
    public func start(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        locationManager.startUpdatingLocation()
    }
    
    public func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    public func request(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        locationManager.requestLocation()
    }
    
//    public func request() async -> CLLocation? {
//        await withCheckedContinuation { continuation in
//            self.request { location in
//                continuation.resume(returning: location)
//            }
//        }
//    }
}

extension TnLocation: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        completion?(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        logError(error)
        location = nil
        completion?(location)
    }
}
