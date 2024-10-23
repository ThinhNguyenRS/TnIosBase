//
//  TnNetworkTCP.swift
//  tCamera
//
//  Created by Thinh Nguyen on 9/4/24.
//

import Foundation
import Network

// MARK: TnNetworkDelegate
public protocol TnNetworkDelegate {
    func tnNetworkReady(_ connection: TnNetworkConnection)
    func tnNetworkStop(_ connection: TnNetworkConnection, error: Error?)
}

// MARK: TnNetworkHostInfo
public protocol TnNetworkDelegateServer {
    func tnNetworkReady(_ server: TnNetworkServer)
    func tnNetworkStop(_ server: TnNetworkServer, error: Error?)
    func tnNetworkStop(_ server: TnNetworkServer, connection: TnNetworkConnection, error: Error?)
    func tnNetworkAccepted(_ server: TnNetworkServer, connection: TnNetworkConnection)
}

// MARK: TnNetworkHostInfo
public struct TnNetworkHostInfo: Codable, Equatable, Hashable {
    public let host: String
    public let port: UInt16
    
    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
}

// MARK: NWEndpoint
extension NWEndpoint {
    public func getHostInfo() -> TnNetworkHostInfo {
        switch self {
        case .hostPort(let host, let port):
            return TnNetworkHostInfo(host: "\(host)", port: port.rawValue)
        default:
            return TnNetworkHostInfo(host: "", port: 0)
        }
    }
}
