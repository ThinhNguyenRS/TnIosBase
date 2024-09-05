//
//  TnAsync.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 11/1/21.
//

import Foundation

func mainAsync(action: @escaping () throws -> Void, onError: ((Error) -> Void)? = nil, onComplete: (() -> Void)? = nil) {
    DispatchQueue.main.async {
        do {
            try action()
        } catch {
            onError?(error)
        }
        onComplete?()
    }
}
