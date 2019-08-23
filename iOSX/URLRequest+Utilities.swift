//
//  URLRequest+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 3/16/17.
//  Copyright © 2017 Frank Vernon. All rights reserved.
//

#if os(iOS)
import UIKit
#endif

#if os(OSX)
import AppKit
#endif

fileprivate let rfc2822LineEnding:String = "\r\n"

public extension URLRequest {
    #if os(iOS)
    /**
     Appends a UIImage as a form section to a URLRequest body as JPEG.
     
     - Parameter boundary: The boundary for the form section
     - Parameter image: The image to include in the form section
     - Parameter fileName: The filename for the form section
     - Parameter isFinal: Boolean indicating if a MIME boundary termination should be included
     
     - Returns: True if form section was appended, false otherwise
     */
    @discardableResult mutating func appendJPEGImageFormSection(withBoundary boundary:String = UUID().uuidString,
                                                                image:UIImage,
                                                                fileName:String,
                                                                name:String? = nil,
                                                                isFinal:Bool = false) -> Bool {
        guard let scaledImageData:Data = image.jpegData(compressionQuality: 1.0) else {
            return false
        }
        
        return appendFormSection(withBoundary: boundary,
                                 mimeType: "image/jpeg",
                                 name: name ?? "data",
                                 fileName: fileName,
                                 contentData: scaledImageData,
                                 isFinal: isFinal)
    }
    #endif
    
    #if os(OSX)
    /**
     Appends a NSImage as a form section to a URLRequest body as JPEG.
     
     - Parameter boundary: The boundary for the form section
     - Parameter image: The image to include in the form section
     - Parameter fileName: The filename for the form section
     - Parameter isFinal: Boolean indicating if a MIME boundary termination should be included
     
     - Returns: True if form section was appended, false otherwise
     */
    @discardableResult mutating func appendJPEGImageFormSection(withBoundary boundary:String = UUID().uuidString,
                                                                image:NSImage,
                                                                fileName:String,
                                                                name:String? = nil,
                                                                isFinal:Bool = false) -> Bool {
        guard let bits = image.representations.first as? NSBitmapImageRep,
            let scaledImageData = bits.representation(using: .jpeg, properties: [:]) else {
                return false
        }
        
        return appendFormSection(withBoundary: boundary,
                                 mimeType: "image/jpeg",
                                 name: name ?? "data",
                                 fileName: fileName,
                                 contentData: scaledImageData,
                                 isFinal: isFinal)
    }
    #endif
    
    /**
     Appends a form section to a URLRequest body.
     
     - Parameter boundary: The boundary for the form section
     - Parameter mimeType: The mime type for the form section
     - Parameter name: The name for the form section
     - Parameter fileName: The filename for the form section
     - Parameter contentData: The content data for the form section
     - Parameter isFinal: Boolean indicating if a MIME boundary termination should be included
     
     - Returns: True if form section was appended, false otherwise
     */
    @discardableResult mutating func appendFormSection(withBoundary boundary:String = UUID().uuidString,
                                                       mimeType:String? = nil,
                                                       name:String,
                                                       fileName:String? = nil,
                                                       contentData:Data,
                                                       isFinal:Bool = false) -> Bool {
        //Ensure Content-Type header on the request is set
        self.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        //Create section boundary and section header
        //boundary
        var boundaryHeader:String = "--\(boundary)"
        boundaryHeader += rfc2822LineEnding
        
        //section headers
        boundaryHeader += "Content-Disposition: form-data; name=\"\(name)\""
        if let fileName = fileName {
            boundaryHeader += "; filename=\"\(fileName)\""
        }
        boundaryHeader += rfc2822LineEnding
        
        if let mimeType = mimeType {
            boundaryHeader += "Content-Type: \(mimeType)"
            boundaryHeader += rfc2822LineEnding
        }
        
        //add terminating line ending for header section
        boundaryHeader += rfc2822LineEnding
        
        guard let boundaryHeaderData:Data = boundaryHeader.data(using: String.Encoding.utf8) else {
            return false
        }
        
        var section:Data = Data()
        section.append(boundaryHeaderData)
        section.append(contentData)
        
        //add section termination
        var boundaryTermination = rfc2822LineEnding
        if isFinal {
            boundaryTermination += "--\(boundary)--" + rfc2822LineEnding
        }
        
        guard let boundaryTerminationData:Data = boundaryTermination.data(using: String.Encoding.utf8) else {
            return false
        }
        section.append(boundaryTerminationData)
        
        if httpBody == nil {
            httpBody = Data()
        }
        
        httpBody?.append(section)
        return true
    }
}
