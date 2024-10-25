//
//  TnDoCatch.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 10/24/24.
//

import Foundation

extension TnLoggable {
    public func tnDoCatch(name: String, action: @escaping () throws -> Void) throws {
        do {
            try action()
        } catch {
            logError(name, "error", error.localizedDescription)
            throw error
        }
    }

    public func tnDoCatch<T>(name: String, action: @escaping () throws -> T) throws -> T {
        do {
            return try action()
        } catch {
            logError(name, "error", error.localizedDescription)
            throw error
        }
    }

    public func tnDoCatchAsync(name: String, action: @escaping () async throws -> Void) async throws {
        do {
            try await action()
        } catch {
            logError(name, "error", error.localizedDescription)
            throw error
        }
    }

    public func tnDoCatchAsync<T>(name: String, action: @escaping () async throws -> T) async throws -> T {
        do {
            return try await action()
        } catch {
            logError(name, "error", error.localizedDescription)
            throw error
        }
    }
}
