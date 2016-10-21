//
//  NSURLComponent+Utilities.swift
//  Passenger V2
//
//  Created by Frank Vernon on 5/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

let kURLPathSeperator:String = "/"

public extension URLComponents {    
    mutating func appendPath(_ path:String) {
        var oldPath:String = self.path
        if oldPath.hasSuffix(kURLPathSeperator) {
            oldPath.remove(at: oldPath.index(before: oldPath.endIndex))
        }
        
        var newPath:String = path
        if newPath.hasPrefix(kURLPathSeperator) {
            newPath.remove(at: newPath.startIndex)
        }
        
        self.path = oldPath + kURLPathSeperator + newPath
    }
    
    mutating func appendPathComponents(_ paths:[String]) {
        for path in paths {
            appendPath(path)
        }
    }
    
    mutating func appendQueryParameter(_ parameter:URLQueryItem) {
        var currentParams = queryItems
        if currentParams != nil {
            currentParams!.append(parameter)
            queryItems = currentParams
        }
        else {
            queryItems = [parameter]
        }
    }
    
    mutating func appendQueryParameterComponents(_ parameters:[URLQueryItem]) {
        var currentParams = queryItems
        if currentParams != nil {
            currentParams!.append(contentsOf: parameters)
            queryItems = currentParams
        }
        else {
            queryItems = parameters
        }
    }
    
    func URLByAppendingPath(_ path:String? = nil, parameters:[URLQueryItem]? = nil) -> URL? {
        var baseURLCopy = (self as NSURLComponents).copy() as! URLComponents
        
        //append sub-path if supplied
        if let path = path {
            baseURLCopy.appendPath(path)
        }
        
        //append additional parameters is supplied
        if let parameters = parameters {
            baseURLCopy.appendQueryParameterComponents(parameters)
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

public extension NSMutableURLRequest {
    func appendJPEGImageFormSection(_ boundary:String,
                                    image:UIImage,
                                    fileName:String,
                                    isFinal:Bool = false) {
        guard let scaledImageData:Data = UIImageJPEGRepresentation(image, 1.0) else {
            return
        }

        appendFormSection(boundary, mimeType: "image/jpeg", name: "data", fileName: fileName, contentData: scaledImageData, isFinal: isFinal)
    }

    func appendFormSection(_ boundary:String,
                           mimeType:String,
                           name:String,
                           fileName:String,
                           contentData:Data,
                           isFinal:Bool = false) {
        let body:NSMutableData = NSMutableData()
        if let existingBody = httpBody {
            body.append(existingBody)
        }

        _ = body.appendStringAsUTF8("--\(boundary)\r\n")
        _ = body.appendStringAsUTF8("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        _ = body.appendStringAsUTF8("Content-Type: \(mimeType)\r\n\r\n")

        _ = body.append(contentData)

        if isFinal {
            _ = body.appendStringAsUTF8("\r\n--\(boundary)--\r\n")
        }
        
        httpBody = body as Data
    }
}
