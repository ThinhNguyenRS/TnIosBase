//
//  TnNetworkHelper.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 05/08/2021.
//

import Foundation
import Network

public enum TnNetworkInterface: String, Codable {
    case wifi = "en0"
    case cellular = "pdp_ip0"
    case cellularBridge = "bridge100"
    //... case ipv4 = "ipv4"
    //... case ipv6 = "ipv6"
}

public enum TnNetworkAddressType: UInt8, Equatable {
    case ip4
    case ip6
    case unknown
}

extension TnNetworkAddressType {
    public static func fromFamily(_ family: UInt8) -> Self {
        if family == UInt8(AF_INET) {
            return .ip4
        } else if family == UInt8(AF_INET6) {
            return .ip6
        } else {
            return .unknown
        }
    }
    
    func toFamily() {
        
    }
}

public struct TnNetworkAddress {
    public let interface: TnNetworkInterface
    public let address: String
    public let addressType: TnNetworkAddressType
}

public class TnNetworkHelper {
    private init() {}
    
    public static func getAddressList(for interfaces: [TnNetworkInterface], types: [TnNetworkAddressType] = [.ip4]) -> [TnNetworkAddress] {
        var addressList: [TnNetworkAddress] = []
        let interfaceNames = interfaces.map { v in v.rawValue }
        
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return addressList }
        guard let firstAddr = ifaddr else { return addressList }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            let addrType: TnNetworkAddressType = .fromFamily(addrFamily)
            if addrType.isIn(types) {
                
                // Check interface name:
                let interfaceName = String(cString: interface.ifa_name)
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                let hostAddress = String(cString: hostname)
                
                TnLogger.debug("TnNetworkHelper", "getAddress", interfaceName, hostAddress)

                if interfaceName.isIn(interfaceNames) {
                    addressList.append(TnNetworkAddress(interface: TnNetworkInterface(rawValue: interfaceName)!, address: hostAddress, addressType: addrType))
                }
            }
        }
        freeifaddrs(ifaddr)
        
        var ret: [TnNetworkAddress] = []
        for interface in interfaces {
            if let address = addressList.first(where: { v in v.interface == interface}) {
                ret.append(address)
            }
        }
        
        return ret
    }
    
    public static func getAddress(for interface: TnNetworkInterface, type: TnNetworkAddressType = .ip4) -> TnNetworkAddress? {
        getAddressList(for: [interface], types: [type]).first
    }
        
    public static func isWifiConnected() -> Bool {
        getAddress(for: .wifi, type: .ip4) != nil
    }
    
    /// Does a best effort attempt to trigger the local network privacy alert.
    ///
    /// It works by sending a UDP datagram to the discard service (port 9) of every
    /// IP address associated with a broadcast-capable interface. This should
    /// trigger the local network privacy alert, assuming the alert hasn’t already
    /// been displayed for this app.
    ///
    /// This code takes a ‘best effort’. It handles errors by ignoring them. As
    /// such, there’s guarantee that it’ll actually trigger the alert.
    ///
    /// - note: iOS devices don’t actually run the discard service. I’m using it
    /// here because I need a port to send the UDP datagram to and port 9 is
    /// always going to be safe (either the discard service is running, in which
    /// case it will discard the datagram, or it’s not, in which case the TCP/IP
    /// stack will discard it).
    ///
    /// There should be a proper API for this (r. 69157424).
    ///
    /// For more background on this, see [Triggering the Local Network Privacy Alert](https://developer.apple.com/forums/thread/663768).
    public static func triggerLocalNetworkPrivacyAlert() {
        let sock4 = socket(AF_INET, SOCK_DGRAM, 0)
        guard sock4 >= 0 else { return }
        defer { close(sock4) }
        let sock6 = socket(AF_INET6, SOCK_DGRAM, 0)
        guard sock6 >= 0 else { return }
        defer { close(sock6) }
        
        let addresses = addressesOfDiscardServiceOnBroadcastCapableInterfaces()
        var message = [UInt8]("!".utf8)
        for address in addresses {
            address.withUnsafeBytes { buf in
                let sa = buf.baseAddress!.assumingMemoryBound(to: sockaddr.self)
                let saLen = socklen_t(buf.count)
                let sock = sa.pointee.sa_family == AF_INET ? sock4 : sock6
                _ = sendto(sock, &message, message.count, MSG_DONTWAIT, sa, saLen)
            }
        }
    }
    
    /// Returns the addresses of the discard service (port 9) on every
    /// broadcast-capable interface.
    ///
    /// Each array entry is contains either a `sockaddr_in` or `sockaddr_in6`.
    static private func addressesOfDiscardServiceOnBroadcastCapableInterfaces() -> [Data] {
        var addrList: UnsafeMutablePointer<ifaddrs>? = nil
        let err = getifaddrs(&addrList)
        guard err == 0, let start = addrList else { return [] }
        defer { freeifaddrs(start) }
        return sequence(first: start, next: { $0.pointee.ifa_next })
            .compactMap { i -> Data? in
                guard
                    (i.pointee.ifa_flags & UInt32(bitPattern: IFF_BROADCAST)) != 0,
                    let sa = i.pointee.ifa_addr
                else { return nil }
                var result = Data(UnsafeRawBufferPointer(start: sa, count: Int(sa.pointee.sa_len)))
                switch CInt(sa.pointee.sa_family) {
                case AF_INET:
                    result.withUnsafeMutableBytes { buf in
                        let sin = buf.baseAddress!.assumingMemoryBound(to: sockaddr_in.self)
                        sin.pointee.sin_port = UInt16(9).bigEndian
                    }
                case AF_INET6:
                    result.withUnsafeMutableBytes { buf in
                        let sin6 = buf.baseAddress!.assumingMemoryBound(to: sockaddr_in6.self)
                        sin6.pointee.sin6_port = UInt16(9).bigEndian
                    }
                default:
                    return nil
                }
                return result
            }
    }
}


public enum TnNetworkError: Error {
    case notAvailable
    case socketClosed
    case socketError(description: String)
}

public struct TnNetworkPacket {
    let message: TnNetworkMessage
    let ip: String
    
    init(_ message: TnNetworkMessage, ip: String) {
        self.message = message
        self.ip = ip
    }
}

public enum TnNetworkMessageType: UInt8, Codable {
    case queryRequest
    case queryResponse
}

public struct TnNetworkMessage: Codable {
    let type: TnNetworkMessageType
    var json: String? = nil
    let time: String
}

extension TnNetworkMessage {
    public static func create(_ type: TnNetworkMessageType, json: String? = nil) -> TnNetworkMessage {
        let message = TnNetworkMessage(
            type: .queryRequest,
            json: json,
            time: Date.now().toString()
        )
        return message
    }
    
    public static func create<T: Codable>(_ type: TnNetworkMessageType, object: T) -> TnNetworkMessage {
        let json = try? object.toJson()
        return create(type, json: json)
    }
    
    public func getObject<T: Codable>(_ type: T.Type) -> T? {
        json?.toObject(type)
    }
}
