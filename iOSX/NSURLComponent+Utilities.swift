//
//  NSURLComponent+Utilities.swift
//  Passenger V2
//
//  Created by Frank Vernon on 5/26/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

let kURLPathSeperator:String = "/"

public extension NSURLComponents {    
    func appendPath(path:String) {
        if let oldPath = self.path {
            var oldPath:String = oldPath
            if oldPath.hasSuffix(kURLPathSeperator) {
                oldPath.removeAtIndex(oldPath.endIndex.predecessor())
            }
            
            var newPath:String = path
            if newPath.hasPrefix(kURLPathSeperator) {
                newPath.removeAtIndex(newPath.startIndex)
            }
            
            self.path = oldPath + kURLPathSeperator + newPath
        } else {
            self.path = path
        }
    }
    
    func appendPathComponents(paths:[String]) {
        for path in paths {
            appendPath(path)
        }
    }
    
    func appendQueryParameter(parameter:NSURLQueryItem) {
        var currentParams = queryItems
        if currentParams != nil {
            currentParams!.append(parameter)
            queryItems = currentParams
        }
        else {
            queryItems = [parameter]
        }
    }
    
    func appendQueryParameterComponents(parameters:[NSURLQueryItem]) {
        var currentParams = queryItems
        if currentParams != nil {
            currentParams!.appendContentsOf(parameters)
            queryItems = currentParams
        }
        else {
            queryItems = parameters
        }
    }
    
    func URLByAppendingPath(path:String? = nil, parameters:[NSURLQueryItem]? = nil) -> NSURL? {
        let baseURLCopy = self.copy() as! NSURLComponents
        
        //append sub-path if supplied
        if let path = path {
            baseURLCopy.appendPath(path)
        }
        
        //append additional parameters is supplied
        if let parameters = parameters {
            baseURLCopy.appendQueryParameterComponents(parameters)
        }
        
        //ensure base URL is valid (after path/params updated)
        return baseURLCopy.URL
    }
}

public extension NSURLQueryItem {
    public convenience init(name: String, intValue: Int) {
        self.init(name: name, value: String(intValue))
    }
    
    public convenience init(name: String, doubleValue: Double) {
        self.init(name: name, value: String(doubleValue))
    }
    
    public convenience init(name: String, floatValue: Float) {
        self.init(name: name, value: String(floatValue))
    }
    
    public func urlEscapedItem() -> String? {
        guard let encodedName = self.name.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) else {
            return nil
        }
        
        guard let encodedValue = self.value?.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) else {
            return nil
        }
        
        return encodedName + "=" + encodedValue
    }
}
