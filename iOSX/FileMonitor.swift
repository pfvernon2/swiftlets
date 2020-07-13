//
//  FileMonitor.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/11/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import Foundation

public class FileMonitor {
    private var source: DispatchSourceFileSystemObject? = nil

    private (set) var url: URL
    private (set) var event: DispatchSource.FileSystemEvent
    public var completion: (()->Swift.Void)?

    public init(url: URL, event: DispatchSource.FileSystemEvent, completion: (()->Swift.Void)? = nil) {
        self.url = url
        self.event = event
        self.completion = completion
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        let fileDesc = open(url.path, O_EVTONLY)
        
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDesc,
                                                           eventMask: event,
                                                           queue: DispatchQueue.main)
        
        source?.setCancelHandler { [weak self] in
            guard let self = self else {
                return
            }
            close(fileDesc)
            self.source = nil
        }
        
        source?.setEventHandler { [weak self] in
            guard let self = self, let completion = self.completion else {
                return
            }
            
            completion()
        }
        
        source?.resume()
    }
    
    public func stop() {
        source?.cancel()
    }
}

