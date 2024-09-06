//
//  TnWifiHelper.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 11/16/21.
//

import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork

class TnNetworkInfoFetcher: NSObject, CLLocationManagerDelegate {
    struct NetworkInfo {
        var interface: String
        var ssid: String
        var bssid: String
    }
    
    private let locationManager = CLLocationManager()
    private var onFetch: (([NetworkInfo]) -> Void)? = nil
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            fetchNetworkInfos()
        }
    }
    
    func fetch(onSuccess: @escaping ([NetworkInfo]) -> Void) {
        onFetch = onSuccess
        
        if #available(iOS 13.0, *) {
            let status = locationManager.authorizationStatus
            if status == .authorizedWhenInUse {
                fetchNetworkInfos()
            } else {
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
            fetchNetworkInfos()
        }
    }

    private func fetchNetworkInfos() {
        var networkInfos = [NetworkInfo]()
        if let interfaces: NSArray = CNCopySupportedInterfaces() {
            for interface in interfaces {
                if let interfaceName = interface as? String,
                    let dict = CNCopyCurrentNetworkInfo(interfaceName as CFString) as NSDictionary? {
                    if let ssid = dict[kCNNetworkInfoKeySSID as String] as? String,
                       let bssid = dict[kCNNetworkInfoKeyBSSID as String] as? String {
                        let networkInfo = NetworkInfo(
                            interface: interfaceName,
                            ssid: ssid,
                            bssid: bssid)
                        networkInfos.append(networkInfo)
                    }
                }
            }
        }
        onFetch?(networkInfos)
    }
}
