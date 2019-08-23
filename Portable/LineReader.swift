//
//  LineReader.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/7/17.
//  Copyright © 2017 Frank Vernon. All rights reserved.
//

import Foundation

/**
 Utility class and associated Sequence extension to read file delimited by line ending.
 
 - note: This is an old school C style ASCII file input technique. It is not Unicode aware
 and as such may be of limited value. It is intened for processing structured files
 containing ASCII endoded data such as simple log files, for example.
 
 ```
 guard let lineReader:LineReader = LineReader(url: url) else {
     return
 }
 
 for nextLine in lineReader {
     //process nextLine
 }
 ```
 */
class LineReader {
    fileprivate let file: UnsafeMutablePointer<FILE>
    
    init?(path: String) {
        guard let fileRef = fopen(path, "r") else {
            return nil
        }
        
        self.file = fileRef
    }
    
    init?(url: URL) {
        guard url.isFileURL,
            let fileRef = fopen(url.path, "r") else {
                return nil
        }
        
        self.file = fileRef
    }
    
    var nextLine: String? {
        var line:UnsafeMutablePointer<CChar>? = nil
        defer {
            free(line)
        }
        
        var linecap:Int = 0
        guard getline(&line, &linecap, file) > 0, line != nil else {
            return nil
        }
        
        //force unwrap protected by guard above
        return String(cString: line!)
    }
    
    deinit {
        fclose(file)
    }
}

extension LineReader: Sequence {
    func  makeIterator() -> AnyIterator<String> {
        AnyIterator<String> {
            self.nextLine
        }
    }
}
