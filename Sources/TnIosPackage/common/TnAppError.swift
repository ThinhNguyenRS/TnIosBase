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
}
