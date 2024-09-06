//
//  TnURL.swift
//  CustomCameraApp
//
//  Created by Thinh Nguyen on 7/11/24.
//

import Foundation

extension URL {
    func subPath(_ path: String) -> URL {
        self.appendingPathComponent(path)
    }
    
    static func createFolder(_ path: String) throws -> URL {
        let folderPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(path)
        if !FileManager.default.fileExists(atPath: folderPath.path) {
            try FileManager.default.createDirectory(atPath: folderPath.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return folderPath
    }
}
