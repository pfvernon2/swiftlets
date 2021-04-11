//
//  FileManager+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 2/27/21.
//  Copyright © 2021 Frank Vernon. All rights reserved.
//

import Foundation

public extension FileManager {
    var documentsDirectory: URL {
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
          fatalError("unable to locate system document directory")
        }
        
        return docURL
    }
    
    var cacheDirectory: URL {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
          fatalError("unable to locate system cache directory")
        }
        
        return cacheURL
    }
    
    var appSupportDirectory: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
          fatalError("unable to locate system cache directory")
        }
        
        return appSupport

    }
    
    func fileExistsInDocuments(atPath path: String) -> Bool {
        let pathURL: URL = documentsDirectory.appendingPathComponent(path)
        return fileExists(atPath: pathURL.path)
    }
    
    func removeItemInDocuments(atPath path: String) throws {
        let pathURL: URL = documentsDirectory.appendingPathComponent(path)
        try removeItem(at: pathURL)
    }

    var temporaryFile: URL {
        temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }
    
    ///Creates a unique file name in the given directory using the Apple convention of appending
    /// numbers to the end of the file name.
    func uniqueFile(in dir: URL, name: String, type: String) -> URL {
        var result = dir.appendingPathComponent(name).appendingPathExtension(type)
        
        var attempt = 0
        while fileExists(atPath: result.path) {
            attempt += 1
            result = dir.appendingPathComponent("\(name) \(attempt)").appendingPathExtension(type)
        }
        
        return result
    }
}
