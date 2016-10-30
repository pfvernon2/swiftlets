//
//  NSURLComponent+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

let kURLPathSeperator:String = "/"

public extension URLComponents {
    mutating func append(path:String) {
        //strip any trailing path seperators to avoid bad path construction
        var oldPath:String = self.path
        while oldPath.hasSuffix(kURLPathSeperator) {
            oldPath.remove(at: oldPath.index(before: oldPath.endIndex))
        }
        
        //strip any leading path seperators to avoid bad path construction
        var newPath:String = path
        while newPath.hasPrefix(kURLPathSeperator) {
            newPath.remove(at: newPath.startIndex)
        }
        
        self.path = oldPath + kURLPathSeperator + newPath
    }
    
    mutating func append(pathComponents paths:[String]) {
        for path in paths {
            append(path: path)
        }
    }
    
    mutating func append(queryParameter parameter:URLQueryItem) {
        var currentParams = queryItems
        if currentParams != nil {
            currentParams!.append(parameter)
            queryItems = currentParams
        }
        else {
            queryItems = [parameter]
        }
    }
    
    mutating func append(queryParameterComponents parameters:[URLQueryItem]) {
        var currentParams = queryItems
        if currentParams != nil {
            currentParams!.append(contentsOf: parameters)
            queryItems = currentParams
        }
        else {
            queryItems = parameters
        }
    }
    
    func URLByAppending(path:String? = nil, parameters:[URLQueryItem]? = nil) -> URL? {
        var baseURLCopy = (self as NSURLComponents).copy() as! URLComponents
        
        //append sub-path if supplied
        if let path = path {
            baseURLCopy.append(path: path)
        }
        
        //append additional parameters is supplied
        if let parameters = parameters {
            baseURLCopy.append(queryParameterComponents: parameters)
        }
        
        //ensure base URL is valid (after path/params updated)
        return baseURLCopy.url
    }
}

public extension URLQueryItem {
    public init(name: String, intValue: Int) {
        self.init(name: name, value: String(intValue))
    }
    
    public init(name: String, doubleValue: Double) {
        self.init(name: name, value: String(doubleValue))
    }
    
    public init(name: String, floatValue: Float) {
        self.init(name: name, value: String(floatValue))
    }
    
    public func urlEscapedItem() -> String? {
        guard let encodedName = self.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        guard let encodedValue = self.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return encodedName + "=" + encodedValue
    }
}

fileprivate let rfc2822LineEnding:String = "\r\n"

public extension NSMutableURLRequest {
    func appendJPEGImageFormSection(withBoundary boundary:String,
                                    image:UIImage,
                                    fileName:String,
                                    isFinal:Bool = false) {
        guard let scaledImageData:Data = UIImageJPEGRepresentation(image, 1.0) else {
            return
        }

        appendFormSection(withBoundary: boundary, mimeType: "image/jpeg", name: "data", fileName: fileName, contentData: scaledImageData, isFinal: isFinal)
    }

    func appendFormSection(withBoundary boundary:String,
                           mimeType:String,
                           name:String,
                           fileName:String,
                           contentData:Data,
                           isFinal:Bool = false) {
        var boundaryHeader:String = "--\(boundary)" + rfc2822LineEnding
        boundaryHeader += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\""  + rfc2822LineEnding
        boundaryHeader += "Content-Type: \(mimeType)" + rfc2822LineEnding
        boundaryHeader += rfc2822LineEnding

        guard let boundaryHeaderData:Data = boundaryHeader.data(using: String.Encoding.utf8) else {
            return
        }
        
        var section:Data = Data()
        section.append(boundaryHeaderData)
        section.append(contentData)
        if isFinal {
            let boundaryTermination = rfc2822LineEnding + "--\(boundary)--" + rfc2822LineEnding
            guard let boundaryTerminationData:Data = boundaryTermination.data(using: String.Encoding.utf8) else {
                return
            }
            section.append(boundaryTerminationData)
       }
        
        if httpBody == nil {
            httpBody = Data()
        }
        
        httpBody?.append(section)
    }
}
