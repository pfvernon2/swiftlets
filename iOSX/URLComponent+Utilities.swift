//
//  NSURLComponent+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

// MARK: -

///Protocol representing a path string with a uniform seperator as an array of indivdual string components.
/// Use of the protocol normalizes paths to their canonical form, i.e. it removes extraneous path seperators and empty paths.
public protocol pathComponents:CustomStringConvertible {
    //The seperator to be used between elements in the path, for example "/"
    var seperator:Character { get set }
    
    //The components of the path
    var components:[String] { get set }
    
    //An indication of whether the path is fully qualified or not. e.g. it begins at root directory
    var isFullyQualified:Bool { get set }

    //An indication of whether the path is a leaf node or not. e.g. is it a file or a directory
    var isLeaf:Bool { get set }
    
    ///Default initializer, you must implement this in your concrete instance
    init()

    ///Initialize with path as string, implemented in default extension
    init(path:String)
    
    ///Append a path to the current path
    mutating func append(pathComponents:pathComponents)
    
    ///CustomStringConvertible implementation
    var description:String { get }
}

//Default implementation of pathComponents protocol
public extension pathComponents {
    public init(path:String) {
        self.init()
        components = path.components(separatedBy: String(seperator)).filter { (pathComponent) -> Bool in
            return !pathComponent.isEmpty
        }
        isFullyQualified = path.hasPrefix(String(seperator))
        isLeaf = (isFullyQualified && path.characters.count == 1) || !path.hasSuffix(String(seperator))
    }
    
    mutating func append(pathComponents:pathComponents) {
        components.append(contentsOf: pathComponents.components)
        //isFullyQualified - follows parent object
        isLeaf = pathComponents.isLeaf
    }

    var description:String {
        var result:String = components.joined(separator: String(seperator))
        if isFullyQualified {
            result.insert(seperator, at: result.startIndex)
        }
        if !isLeaf {
            result.append(seperator)
        }
        return result
    }
}

//Representation of path components using the unix convention ('/' character) as the seperator.
public struct UnixPathComponents:pathComponents {
    public var seperator: Character = "/"
    public var components: [String] = []
    public var isLeaf: Bool = true
    public var isFullyQualified: Bool = true
    
    public init() {
    }
}

typealias HTTPURLPathComponents = UnixPathComponents
typealias FileURLPathComponents = UnixPathComponents

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
         pathComponents:UnixPathComponents? = nil) {
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
    public var pathComponents:UnixPathComponents {
        get {
            return UnixPathComponents(path: self.path)
        }
        
        set (pathComponents) {
            self.path = pathComponents.description
        }
    }
        
    ///Append multiple path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(pathComponents components:UnixPathComponents) {
        var components = self.pathComponents
        components.append(pathComponents: components)
        self.pathComponents = components
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
    func URLByAppending(pathComponents components:UnixPathComponents? = nil, parameters:[URLQueryItem]? = nil) -> URL? {
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
