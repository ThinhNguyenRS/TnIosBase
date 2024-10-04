//
//  TnAppError.swift
//  CustomCameraApp
//
//  Created by Thinh Nguyen on 7/11/24.
//

import Foundation

public enum TnAppError: Error {
    case general(message: String)
}

extension TnAppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .general(let message):
            return message.lz()
        }
    }
    
    public static func from(_ error: Error) -> Self {
        .general(message: error.localizedDescription)
    }
    
    public static func from(_ errorString: String) -> Self {
        .general(message: errorString)
    }
    
    public static func from(_ errorString: String, _ error: Error?) -> Self {
        .general(message: "\(errorString): \(error?.localizedDescription ?? "")")
    }
}

public func tnDoCatch(name: String, action: @escaping () throws -> Void) throws {
    do {
        try action()
    } catch {
        TnLogger.error(name, error.localizedDescription)
        throw error
    }
}

public func tnDoCatch<T>(name: String, action: @escaping () throws -> T) throws -> T {
    do {
        return try action()
    } catch {
        TnLogger.error(name, error.localizedDescription)
        throw error
    }
}

public func tnDoCatchAsync(name: String, action: @escaping () async throws -> Void) async throws {
    do {
        try await action()
    } catch {
        TnLogger.error(name, error.localizedDescription)
        throw error
    }
}
