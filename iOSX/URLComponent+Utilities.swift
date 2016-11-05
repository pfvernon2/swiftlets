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
    //Enumeration for most common URL schemes
    public enum urlSchemes: String {
        case http, file
    }
    
    ///Convenience initializer to build object from components
    init(scheme:urlSchemes? = nil, host:String? = nil, port:Int? = nil, user:String? = nil, password:String? = nil, pathComponents:[String]? = nil) {
        self.init()
        self.scheme = scheme?.rawValue
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        if let pathComponents = pathComponents {
            append(pathComponents: pathComponents)
        }
    }
    
    ///Access path as array of path components
    public var pathComponents:[String] {
        get {
            return self.path.components(separatedBy: kURLPathSeperator)
        }
        
        set (pathComponents) {
            self.path.removeAll()
            append(pathComponents: pathComponents)
        }
    }
    
    ///Append a path component to the current path. Extraneous path seperators will be automatically removed.
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
    
    ///Append multiple path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(pathComponents paths:[String]) {
        for path in paths {
            append(path: path)
        }
    }
    
    ///Append a query parameter to the current set of query parameters.
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
    
    ///Append multiple query parameters to the current set of query parameters.
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

    ///Create and return URL based on current components by appending supplied paths and parameters.
    /// This is useful for working with templated URLs where path and/or query may vary.
    ///
    ///- Note: This method DOES NOT mutate the URLComponent object.
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
    
    ///Utility method to return the URL Query Item description with the name and value escaped for use in a URL query
    public func urlEscapedDescription() -> String? {
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

public extension URLRequest {
    /**
     Appends a UIImage as a form section to a URLRequest body.
     
     - Parameter boundary: The boundary for the form section
     - Parameter image: The image to include in the form section
     - Parameter fileName: The filename for the form section
     - Parameter isFinal: Boolean indicating if a MIME boundary termination should be included
     
     - Returns: True if form section was appended, false otherwise
     */
    @discardableResult mutating func appendJPEGImageFormSection(withBoundary boundary:String = UUID().uuidString,
                                    image:UIImage,
                                    fileName:String,
                                    isFinal:Bool = false) -> Bool {
        guard let scaledImageData:Data = UIImageJPEGRepresentation(image, 1.0) else {
            return false
        }

        return appendFormSection(withBoundary: boundary,
                                 mimeType: "image/jpeg",
                                 name: "data",
                                 fileName: fileName,
                                 contentData: scaledImageData,
                                 isFinal: isFinal)
    }

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
                           mimeType:String,
                           name:String,
                           fileName:String,
                           contentData:Data,
                           isFinal:Bool = false) -> Bool {
        var boundaryHeader:String = "--\(boundary)" + rfc2822LineEnding
        boundaryHeader += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\""  + rfc2822LineEnding
        boundaryHeader += "Content-Type: \(mimeType)" + rfc2822LineEnding
        boundaryHeader += rfc2822LineEnding

        guard let boundaryHeaderData:Data = boundaryHeader.data(using: String.Encoding.utf8) else {
            return false
        }
        
        var section:Data = Data()
        section.append(boundaryHeaderData)
        section.append(contentData)
        if isFinal {
            let boundaryTermination = rfc2822LineEnding + "--\(boundary)--" + rfc2822LineEnding
            guard let boundaryTerminationData:Data = boundaryTermination.data(using: String.Encoding.utf8) else {
                return false
            }
            section.append(boundaryTerminationData)
       }
        
        if httpBody == nil {
            httpBody = Data()
        }
        
        httpBody?.append(section)
        return true
    }
}
