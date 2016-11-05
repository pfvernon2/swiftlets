//
//  NSURLComponent+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

// MARK: -

let kCommonPathSeperator:Character = "/"

///Trivial protocol to represent a path a with common seperator as an object with indivdual components
public protocol pathComponents:CustomStringConvertible {
    //The seperator to be used between elements in the path, for example "/"
    var seperator:Character { get set }
    
    //The components of the path
    var components:[String] { get set }
    var count:Int { get }
    
    //An indication of whether the path is a leaf node. e.g is it a file or a directory
    var isLeaf:Bool { get set }
    
    ///Append a path component to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(path:String)
    
    ///Append multiple path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(components:[String], isLeaf:Bool)
    
    ///Append path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(pathComponents:pathComponents)

    var description:String { get }
}

//Default implementation of pathComponents protocol
public extension pathComponents {
    var count:Int {
        get {
            return components.count
        }
    }
    
    mutating func append(path:String) {
        let components = path.components(separatedBy: String(seperator))
        append(components: components)
        self.isLeaf = !path.hasSuffix(String(seperator))
    }

    mutating func append(components:[String], isLeaf:Bool = true) {
        for component in components {
            _append(path: component)
        }
        self.isLeaf = isLeaf
    }

    mutating func append(pathComponents:pathComponents) {
        self.components.append(contentsOf: pathComponents.components)
        self.isLeaf = pathComponents.isLeaf
    }
    
    var description:String {
        var result:String = components.joined(separator: String(seperator))
        if !isLeaf {
            result.append(seperator)
        }
        return result
    }
    
    private mutating func _append(path:String) {
        var newPath = path
        
        //strip leading path seperators
        while newPath.hasPrefix(String(seperator)) {
            newPath.remove(at: newPath.startIndex)
        }
        
        //strip trailing path seperators
        while newPath.hasSuffix(String(seperator)) {
            newPath.remove(at: newPath.index(before: newPath.endIndex))
        }
        
        guard newPath.characters.count > 0 else {
            return
        }

        components.append(newPath)
    }
}

//Representation of path components using the common '/' character as the seperator.
public struct CommonPathComponents:pathComponents {
    public var isLeaf: Bool = true
    public var components: [String] = []
    public var seperator: Character = kCommonPathSeperator
    
    init(path:String) {
        append(path: path)
    }
    
    init(components:[String]) {
        append(components: components)
    }
}

typealias FilePathComponents = CommonPathComponents
typealias HTTPPathComponents = CommonPathComponents

// MARK: -

public extension URLComponents {
    //Enumeration for common URL schemes
    public enum urlSchemes: String {
        case http, file
    }
    
    ///Convenience initializer to build object from components rather than from string or URL
    init(scheme:urlSchemes? = nil,
         host:String? = nil,
         port:Int? = nil,
         user:String? = nil,
         password:String? = nil,
         pathComponents:CommonPathComponents? = nil) {
        self.init()
        self.scheme = scheme?.rawValue
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        if let pathComponents = pathComponents {
            self.path = pathComponents.description
        }
    }
    
    ///Access path as array of path components
    public var pathComponents:CommonPathComponents {
        get {
            return CommonPathComponents(path: self.path)
        }
        
        set (pathComponents) {
            self.path = pathComponents.description
        }
    }
    
    ///Append a path component to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(path:String) {
        var components = self.pathComponents
        components.append(path: path)
        self.pathComponents = components
    }
    
    ///Append multiple path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(pathComponents components:CommonPathComponents) {
        var components = self.pathComponents
        components.append(pathComponents: components)
        self.pathComponents = components
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
    func URLByAppending(pathComponents components:CommonPathComponents? = nil, parameters:[URLQueryItem]? = nil) -> URL? {
        var baseURLCopy = (self as NSURLComponents).copy() as! URLComponents
        
        //append sub-path if supplied
        if let components = components {
            baseURLCopy.append(pathComponents: components)
        }
        
        //append additional parameters is supplied
        if let parameters = parameters {
            baseURLCopy.append(queryParameterComponents: parameters)
        }
        
        //ensure base URL is valid (after path/params updated)
        return baseURLCopy.url
    }
}

// MARK: -

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

// MARK: -

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
