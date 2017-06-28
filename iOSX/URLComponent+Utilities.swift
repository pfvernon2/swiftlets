//
//  NSURLComponent+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

// MARK: - pathComponents

///Protocol representing a path string with a uniform seperator as an array of indivdual string components.
/// Use of the protocol normalizes paths to their canonical form, i.e. it removes extraneous path seperators and empty paths.
public protocol pathComponents:CustomStringConvertible {
    ///The seperator to be used between elements in the path, for example "/"
    var seperator:Character { get set }
    
    ///The components of the path
    var components:[String] { get set }
    
    ///An indication of whether the path is fully qualified or not. e.g. it begins at the root directory
    ///
    /// - note: This value should defualt to 'true' in implementions where you prefer to return
    /// a fully qualified path immediatley after initialization. See UnixPathComponents for example.
    var isFullyQualified:Bool { get set }
    
    ///An indication of whether the path is a leaf node or not. e.g. is it a file or a directory
    var isLeaf:Bool { get set }
    
    ///Default initializer, you must implement this in your concrete instance
    init()
    
    ///Initialize with path as string, implemented in default extension
    init(path:String)
    
    ///Initialize with multiple paths as strings, implemented in default extension
    init(paths:[String])

    ///Append a path to the current path
    mutating func append(pathComponents:pathComponents)
    
    ///CustomStringConvertible implementation
    var description:String { get }
}

//Default implementation of pathComponents protocol
public extension pathComponents {
    public init(path:String) {
        self.init()
        components = []
        append(paths:[path])
    }
    
    public init(paths:[String]) {
        self.init()
        components = []
        append(paths:paths)
    }
    
    mutating func append(paths:[String]) {
        paths.forEach { (path) in
            components += path.components(separatedBy: String(seperator)).filter { (pathComponent) -> Bool in
                return !pathComponent.isEmpty
            }
        }
        isFullyQualified = paths.first?.hasPrefix(String(seperator)) ?? false
        isLeaf = !(paths.last?.hasSuffix(String(seperator)) ?? false)
    }
    
    mutating func append(pathComponents:pathComponents) {
        components.append(contentsOf: pathComponents.components)
        //isFullyQualified - follows parent object
        isLeaf = pathComponents.isLeaf
    }
    
    var description:String {
        var result:String = String()
        
        if isFullyQualified {
            result.append(seperator)
        }
        
        if !components.isEmpty {
            result.append(components.joined(separator: String(seperator)))
        }
        
        if !isLeaf && !components.isEmpty {
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
    //default is true so that we return fully qualified path immediatly after initialization
    public var isFullyQualified: Bool = true
    
    public init() {
    }
}

public typealias HTTPURLPathComponents = UnixPathComponents
public typealias FileURLPathComponents = UnixPathComponents

// MARK: - URLComponents

public extension URLComponents {
    //Enumeration for common URL schemes
    public enum urlSchemes: String {
        case http, https, file
    }
    
    ///Convenience initializer to build object from components rather than from string or URL
    init(scheme:urlSchemes? = nil,
         host:String? = nil,
         port:Int? = nil,
         user:String? = nil,
         password:String? = nil,
         pathComponents:HTTPURLPathComponents? = nil) {
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
    public var pathComponents:HTTPURLPathComponents {
        get {
            return HTTPURLPathComponents(path: self.path)
        }
        
        set (pathComponents) {
            self.path = pathComponents.description
        }
    }
    
    ///Append multiple path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(path:String) {
        let pathComponents:HTTPURLPathComponents = HTTPURLPathComponents(path:path)
        append(pathComponents: pathComponents)
    }
    
    ///Append multiple path components to the current path. Extraneous path seperators will be automatically removed.
    mutating func append(pathComponents components:HTTPURLPathComponents) {
        var currentPathComponents = self.pathComponents
        currentPathComponents.append(pathComponents: components)
        self.pathComponents = currentPathComponents
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
    func URLByAppending(pathComponents components:HTTPURLPathComponents? = nil, parameters:[URLQueryItem]? = nil) -> URL? {
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
    
    var queryItemDictionary:[String:String]? {
        get {
            guard let queryItems = queryItems else {
                return nil
            }
            
            let queryItemPairs:[(String,String)] = queryItems.map { (queryItem) -> (String,String) in
                return (queryItem.name, queryItem.value ?? "")
            }
            return Dictionary(queryItemPairs)
        }
    }
}

// MARK: - NSCharacterSet

public extension NSCharacterSet {
    public static let urlQueryItemParamAndValueAllowed:CharacterSet = {
        var allowedQueryParamAndKey = NSCharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
        return allowedQueryParamAndKey
    }()
}

// MARK: - URLQueryItem

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
        guard let encodedName = self.name.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryItemParamAndValueAllowed) else {
            return nil
        }
        
        guard let encodedValue = self.value?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryItemParamAndValueAllowed) else {
            return nil
        }
        
        return "\(encodedName) = \(encodedValue)"
    }
    
    static func urlEscapedDescription(queryItems:[URLQueryItem]) -> String? {
        return queryItems.flatMap { (queryItem) -> String? in
            return queryItem.urlEscapedDescription()
        }.joined(separator: "&")
    }
}

