//
//  NSURLSession+JSON.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//
// Based upon: https://github.com/dankogai/swift-json
// Copyright (c) 2014 Dan Kogai

import Foundation

/**
 Protocol one can adopt to convert to and from JSON primative types: Number, String, NULL, Array, Dictionary
 
 Example of protocol extension on Date to transform to/from ISO8601 date format:
 ```
 extension Date: JSONTransformable {
     public func toJSONType() -> JSON {
         return JSON(ISO8601DateFormatter().string(from: self))
     }
     
     public static func fromJSONType(json:JSON) -> Date? {
         guard let jsonString:String = json.asString else {
             return nil
     }
     
         return ISO8601DateFormatter().date(from: jsonString)
     }
 }
 ```
 */
public protocol JSONTransformable {
    func toJSONType() -> JSON
    static func fromJSONType(json:JSON) -> Self?
}

/**
 Representation of a JSON element which may have a nil (NULL) value. Nil values
 will be substitued with NSNull() objects automatically when added to a JSON object.
 
 This is useful primarily for creating JSON objects where the value may be nil.
 */
public typealias JSONElement = [String:Any?]

/// init
final public class JSON {
    fileprivate var value:Any = NSNull()
    
    /// unwraps the object to JSON values
    public class func unwrap(_ obj:Any?) -> Any {
        guard let obj = obj else {
            return NSNull()
        }
        
        switch obj {
        case let json as JSON:
            return json.value
            
        case let transform as JSONTransformable:
            return unwrap(transform.toJSONType())
            
        case let element as JSONElement:
            return element.mapPairs { (key, value) in (key, unwrap(value)) }
            
        case let array as Array<Any>:
            return array.map { unwrap($0) }
            
        case let dictionary as Dictionary<String, Any>:
            return dictionary.mapPairs { (key, value) in (key, unwrap(value)) }
            
        case is Int, is Int8, is Int16, is Int32, is Int64:
            fallthrough
            
        case is UInt, is UInt8, is UInt16, is UInt32, is UInt64:
            fallthrough

        case is Double, is Float:
            fallthrough
            
        case is Bool, is String:
            fallthrough

        case is NSNull, is NSError:
            return obj

        default:
            assert(false, "not a valid type for JSON encoding")
            return NSError(
                domain:"JSONErrorDomain",
                code:422,
                userInfo:[NSLocalizedDescriptionKey: "not a valid type for JSON encoding"]
            )
        }
    }
    
    public init(_ object:Any?) {
        self.value = JSON.unwrap(object)
    }
    
    public init(json:JSON) {
        self.value = json.value
    }
}

/// class properties
extension JSON {
    public typealias NSNull = Foundation.NSNull
    public typealias NSError = Foundation.NSError
    public class var null:NSNull {
        return NSNull()
    }
    
    /// constructs JSON object from data
    public convenience init(data:Data) {
        var err:NSError?
        var obj:Any?
        do {
            obj = try JSONSerialization.jsonObject(with: data, options:[])
        } catch let error as NSError {
            err = error
            obj = nil
        }
        self.init(err != nil ? err! : obj!)
    }
    
    /// constructs JSON object from string
    public convenience init(string:String) {
        self.init(data: string.data(using: .utf8)!)
    }
    
    /// parses string to the JSON object
    /// same as JSON(string:String)
    public class func parse(string:String)->JSON {
        return JSON(string:string)
    }
    
    /// constructs JSON object from the content of URL
    /// Note that this blocks the calling thread for IO operations
    public convenience init(contentsOf url:URL) {
        do {
            let str = try String(contentsOf: url)
            self.init(string:str as String)
        } catch let err as NSError {
            self.init(err)
        }
    }
    
    /// fetch the JSON string from URL and parse it
    /// same as JSON(contentsOf:URL)
    public class func from(url:URL) -> JSON {
        return JSON(contentsOf:url)
    }
    
    /// Convert JSON object to Data using UTF8 encoding
    public func toData() -> Data? {
        return toString(prettyPrint: false).data(using: .utf8)
    }
    
    /// Convert any object to JSON encoded string with optional pretty printing.
    /// - Returns: Error object as JSON on failure.
    public class func stringify(obj:Any, prettyPrint:Bool = false) -> String {
        guard JSONSerialization.isValidJSONObject(obj) else {
            let error = JSON(NSError(
                domain:"JSONErrorDomain",
                code:422,
                userInfo:[NSLocalizedDescriptionKey: "not a JSON object"]
            ))
            return JSON(error).toString(prettyPrint: prettyPrint)
        }
        
        return JSON(obj).toString(prettyPrint: prettyPrint)
    }
}

/// instance properties
extension JSON {
    /// Access elements with array syntax
    /// - Returns: Error object as JSON on failure.
    public subscript(index:Int) -> JSON {
        get {
            switch value {
            case _ as NSError:
                return self
            case let array as Array<Any>:
                if 0 <= index && index < array.count {
                    return JSON(array[index])
                }
                return JSON(NSError(
                    domain:"JSONErrorDomain", code:404, userInfo:[
                        NSLocalizedDescriptionKey:
                        "[\(index)] out of range"
                    ]))
            default:
                return JSON(NSError(
                    domain:"JSONErrorDomain", code:500, userInfo:[
                        NSLocalizedDescriptionKey: "not an array"
                    ]))
            }
        }
        
        set (newValue) {
            updateValue(newValue, atIndex: index)
        }
    }
    
    /// Access elements with dictionary syntax
    /// - Returns: Error object as JSON on failure.
    public subscript(key:String)->JSON {
        get {
            switch value {
            case _ as NSError:
                return self
            case let dictionary as Dictionary<String, Any>:
                if let val:Any = dictionary[key] { return JSON(val) }
                return JSON(NSError(
                    domain:"JSONErrorDomain", code:404, userInfo:[
                        NSLocalizedDescriptionKey:
                        "[\"\(key)\"] not found"
                    ]))
            default:
                return JSON(NSError(
                    domain:"JSONErrorDomain", code:500, userInfo:[
                        NSLocalizedDescriptionKey: "not an object"
                    ]))
            }
        }
        
        set (newValue) {
            updateValue(newValue, forKey: key)
        }
    }
    
    public func removeValue(forKey key:String) {
        switch value {
        case var valueDictionary as Dictionary<String, Any>:
            valueDictionary.removeValue(forKey: key)
            value = valueDictionary
        default:
            break
        }
    }
    
    public func remove(at index:Int) {
        switch value {
        case var valueArray as Array<Any>:
            valueArray.remove(at: index)
            value = valueArray
        default:
            break
        }
    }
    
    public func updateValue(_ value:Any?, forKey key:String) {
        let json:JSON = JSON(value)
        switch self.value {
        case var valueDictionary as Dictionary<String, Any>:
            valueDictionary[key] = json.value
            self.value = valueDictionary
        default:
            break
        }
    }
    
    public func updateValue(_ value:Any?, atIndex index:Int) {
        let json:JSON = JSON(value)
        switch self.value {
        case var valueArray as Array<Any>:
            valueArray[index] = json.value
            self.value = valueArray
        default:
            break
        }
    }
    
    /// Access json value object
    public var valueObject:Any? {
        return self.isError ? nil : self.value
    }
    
    /// Gives the type name as string.
    /// e.g.  if it returns "Double"
    ///       .asDouble returns Double
    public var type:String {
        switch value {
        case is NSError:        return "NSError"
        case is NSNull:         return "NSNull"
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":              return "Bool"
            case "q", "l", "i", "s":    return "Int"
            case "Q", "L", "I", "S":    return "UInt"
            default:                    return "Double"
            }
        case is NSString:               return "String"
        case is NSArray:                return "Array"
        case is NSDictionary:           return "Dictionary"
        default:                        return "NSError"
        }
    }
    
    /// check if self is NSError
    public var isError:      Bool { return value is NSError }
    /// check if self is NSNull
    public var isNull:       Bool { return value is NSNull }
    /// check if self is Bool
    public var isBool:       Bool { return type == "Bool" }
    /// check if self is Int
    public var isInt:        Bool { return type == "Int" }
    /// check if self is UInt
    public var isUInt:       Bool { return type == "UInt" }
    /// check if self is Double
    public var isDouble:     Bool { return type == "Double" }
    /// check if self is any type of number
    public var isNumber:     Bool {
        if let o = value as? NSNumber {
            let t = String(cString: o.objCType)
            return  t != "c" && t != "C"
        }
        return false
    }
    
    /// check if self is String
    public var isString:     Bool { return value is NSString }
    /// check if self is Array
    public var isArray:      Bool { return value is NSArray }
    /// check if self is Dictionary
    public var isDictionary: Bool { return value is NSDictionary }
    /// check if self is a valid leaf node.
    public var isLeaf:       Bool {
        return !(isArray || isDictionary || isError)
    }
    
    /// gives NSError if it holds the error. nil otherwise
    public var asError:NSError? {
        return value as? NSError
    }
    
    /// gives NSNull if self holds it. nil otherwise
    public var asNull:NSNull? {
        return value is NSNull ? JSON.null : nil
    }
    
    /// gives Bool if self holds it. nil otherwise
    public var asBool:Bool? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":  return Bool(o.boolValue)
            default:
                return nil
            }
        default: return nil
        }
    }
    
    /// gives Int if self holds it. nil otherwise
    public var asInt:Int? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return Int(o.int64Value)
            }
        default: return nil
        }
    }
    
    /// gives UInt if self holds it. nil otherwise
    public var asUInt:UInt? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return UInt(o.uintValue)
            }
        default: return nil
        }
    }
    
    /// gives Int32 if self holds it. nil otherwise
    public var asInt32:Int32? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return Int32(o.int64Value)
            }
        default: return nil
        }
    }
    
    /// gives Int64 if self holds it. nil otherwise
    public var asInt64:Int64? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return Int64(o.int64Value)
            }
        default: return nil
        }
    }
    
    /// gives Int32 if self holds it. nil otherwise
    public var asUInt32:UInt32? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return UInt32(o.uint64Value)
            }
        default: return nil
        }
    }
    
    /// gives Int64 if self holds it. nil otherwise
    public var asUInt64:UInt64? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return UInt64(o.uint64Value)
            }
        default: return nil
        }
    }
    
    /// gives Float if self holds it. nil otherwise
    public var asFloat:Float? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return Float(o.floatValue)
            }
        default: return nil
        }
    }
    
    /// gives Double if self holds it. nil otherwise
    public var asDouble:Double? {
        switch value {
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return nil
            default:
                return Double(o.doubleValue)
            }
        default: return nil
        }
    }
    
    /// an alias to asDouble
    public var asNumber:Double? { return asDouble }
    
    /// gives String if self holds it. nil otherwise
    public var asString:String? {
        switch value {
        case let o as NSString:
            return o as String
        default: return nil
        }
    }
    
    /// if self holds Array, gives a [JSON]
    /// with elements therein. nil otherwise
    public var asArray:[JSON]? {
        switch value {
        case let array as NSArray:
            var result = [JSON]()
            for v:Any in array {
                result.append(JSON(v))
            }
            return result
        default:
            return nil
        }
    }
    
    /// if self holds Dictionary, gives a [String:JSON]
    /// with elements therein. nil otherwise
    /// - note: This returns a [String:JSON] dictionary for
    /// workig with JSON elements if you need a [String:Any]
    /// dictionary see .asElement
    public var asDictionary:[String:JSON]? {
        switch value {
        case let dictionary as NSDictionary:
            var result = [String:JSON]()
            for (ko, v): (Any, Any) in dictionary {
                if let k = ko as? String {
                    result[k] = JSON(v)
                }
            }
            return result
        default: return nil
        }
    }
    
    /// if self holds Dictionary, gives a JSONElement
    /// with elements therein. nil otherwise
    /// - note: This returns a [String:Any] dictionary for
    /// working with native json types if you need a [String:JSON]
    /// dictionary see .asDictionary
    public var asElement:JSONElement? {
        switch value {
        case let dictionary as NSDictionary:
            var result = JSONElement()
            for (ko, v): (Any, Any) in dictionary {
                if let k = ko as? String {
                    result[k] = v
                }
            }
            return result
        default: return nil
        }
    }
    
    func asTransformable<T:JSONTransformable>() -> T? {
        return T.fromJSONType(json: self)
    }
    
    /// gives the number of elements if an array or a dictionary.
    public var count:Int {
        switch value {
        case let o as NSArray:      return o.count
        case let o as NSDictionary: return o.count
        default: return 0
        }
    }
    
    // gives all values content in JSON object.
    public var values:JSON {
        guard let dictionary = self.asDictionary else {
            return JSON([])
        }
        
        return JSON(dictionary.values)
    }
    
    // gives all keys content in JSON object.
    public var keys:JSON{
        guard let dictionary = self.asDictionary else {
            return JSON([])
        }
        
        return JSON(dictionary.keys)
    }
}

extension JSON : Sequence {
    public func makeIterator()->AnyIterator<(Any,JSON)> {
        switch value {
        case let o as NSArray:
            var i = -1
            return AnyIterator {
                i += 1
                if i == o.count { return nil }
                return (i, JSON(o[i]))
            }
            
        case let o as NSDictionary:
            var ks = Array(o.allKeys.reversed())
            return AnyIterator {
                if ks.isEmpty { return nil }
                if let k = ks.removeLast() as? String {
                    return (k, JSON(o.value(forKey: k)!))
                } else {
                    return nil
                }
            }
            
        default:
            return AnyIterator{ nil }
        }
    }
    
    public func mutableCopyOfTheObject() -> Any? {
        guard let valueObject:NSObject = value as? NSObject else {
            return nil
        }
        return valueObject.mutableCopy()
    }
}

//MARK: - JSON : CustomStringConvertible

extension JSON : CustomStringConvertible {
    public func toString(prettyPrint pretty:Bool = false)->String {
        switch value {
        case is NSError: return "\(value)"
        case is NSNull: return "null"
        case let o as NSNumber:
            switch String(cString: o.objCType) {
            case "c", "C":
                return o.boolValue.description
            case "q", "l", "i", "s":
                return o.int64Value.description
            case "Q", "L", "I", "S":
                return o.uint64Value.description
            default:
                switch o.doubleValue {
                case 0.0/0.0:   return "0.0/0.0"    // NaN
                case -1.0/0.0:  return "-1.0/0.0"   // -infinity
                case +1.0/0.0:  return "+1.0/0.0"   //  infinity
                default:
                    return o.doubleValue.description
                }
            }
        case let o as NSString:
            return o.debugDescription
        default:
            do {
                let opts = pretty ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions()
                let data:Data = try JSONSerialization.data(withJSONObject:value, options:opts)
                if let result = String(data: data, encoding: .utf8) {
                    return result
                }
            } catch {
                print("JSON serialization error")
            }
            
            return ""
        }
    }
    
    public var description:String {
        return toString(prettyPrint: true)
    }
    
    public var debugDescription:String {
        return toString(prettyPrint: true)
    }
}

//MARK: - JSON : Equatable

extension JSON : Equatable {}
public func ==(lhs:JSON, rhs:JSON)->Bool {
    if lhs.isError || rhs.isError {
        return false
    }
    else if lhs.isLeaf {
        if lhs.isNull   { return lhs.asNull   == rhs.asNull }
        if lhs.isBool   { return lhs.asBool   == rhs.asBool }
        if lhs.isNumber { return lhs.asNumber == rhs.asNumber }
        if lhs.isString { return lhs.asString == rhs.asString }
    }
    else if lhs.isArray {
        for i in 0..<lhs.count {
            if lhs[i] != rhs[i] { return false }
        }
        return true
    }
    else if lhs.isDictionary {
        for (k, v) in lhs.asDictionary! {
            if v != rhs[k] { return false }
        }
        return true
    }
    fatalError("JSON == JSON failed!")
}

//MARK: - NSURLSession Extensions

public extension URLSessionConfiguration {
    ///Sensible defaults for a REST style session
    public class func RESTConfiguration() -> URLSessionConfiguration {
        let config:URLSessionConfiguration = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "iOS; REST client"]
        config.timeoutIntervalForRequest = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }
}

//MARK: - URLSession Extensions

public extension URLSession {
    public typealias HTTPSuccessClosure = (HTTPURLResponse, JSON) -> Void
    public typealias HTTPFailureClosure = (HTTPURLResponse? , Error?) -> Void
    
    public enum JSONSessionErrors: Error {
        case invalidQueryItem(String)
        case badHTTPResponse(Data)
    }
    
    public enum HTTPHeaders:String {
        case accept = "Accept"
        case contentType = "Content-Type"
    }
    
    private enum HTTPMethods:String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    private enum HTTPContentType:String {
        case applicationJSON = "application/json"
        case formURLEncoded = "application/x-www-form-urlencoded"
    }
    
    //MARK: - Get
    
    /**
     Perform GET request
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter success: A closure to be called on success. The NSURLResponse and a JSON object will be included.
     - Parameter failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpGet(with url:URL, headers:[String:String]? = nil, success:@escaping HTTPSuccessClosure, failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .get,
                            headers: headers,
                            success: success,
                            failure: failure)
    }
    
    //MARK: - Put
    
    /**
     Perform PUT request with a JSON payload
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter bodyJSON: A JSON object to included as the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter success: A closure to be called on success. The NSURLResponse and a JSON object will be included.
     - Parameter failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPut(with url:URL, bodyJSON:JSON? = nil, headers:[String:String]? = nil, success:@escaping HTTPSuccessClosure, failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .put,
                            headers: headers,
                            contentType: .applicationJSON,
                            body: bodyJSON?.toData(),
                            success: success,
                            failure: failure)
    }
    
    /**
     Perform PUT request with a URL parameter payload
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter bodyParameters: An array of NSURLQueryItem objects to be escaped and included in the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter success: A closure to be called on success. The NSURLResponse and a JSON object will be included.
     - fParameter ailure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPut(with url:URL, bodyParameters:[URLQueryItem], headers:[String:String]? = nil, success:@escaping HTTPSuccessClosure, failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        guard let body:String = URLQueryItem.urlEscapedDescription(queryItems: bodyParameters) else {
            failure(nil, JSONSessionErrors.invalidQueryItem(bodyParameters.description))
            return nil
        }
        
        return httpDataTask(with: url,
                            method: .post,
                            contentType: .formURLEncoded,
                            body: body.data(using: .utf8),
                            success: success,
                            failure: failure)
    }
    
    //MARK: - Post
    
    /**
     Perform POST request with a JSON payload
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter bodyJSON: A JSON object to included as the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter success: A closure to be called on success. The NSURLResponse and a JSON object will be included.
     - Parameter failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPost(with url:URL, bodyJSON:JSON? = nil, headers:[String:String]? = nil, success:@escaping HTTPSuccessClosure, failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .post,
                            headers: headers,
                            contentType: .applicationJSON,
                            body: bodyJSON?.toData(),
                            success: success,
                            failure: failure)
    }
    
    /**
     Perform POST request with a URL parameter payload
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter bodyParameters: An array of NSURLQueryItem objects to be escaped and included in the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter success: A closure to be called on success. The NSURLResponse and a JSON object will be included.
     - fParameter ailure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPost(with url:URL, bodyParameters:[URLQueryItem], headers:[String:String]? = nil, success:@escaping HTTPSuccessClosure, failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        guard let body:String = URLQueryItem.urlEscapedDescription(queryItems: bodyParameters) else {
            failure(nil, JSONSessionErrors.invalidQueryItem(bodyParameters.description))
            return nil
        }
        
        return httpDataTask(with: url,
                            method: .post,
                            contentType: .formURLEncoded,
                            body: body.data(using: .utf8),
                            success: success,
                            failure: failure)
    }
    
    //MARK: - Delete
    
    /**
     Perform DELETE request
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter success: A closure to be called on success. The NSURLResponse and a JSON object will be included.
     - fParameter ailure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpDelete(with url:URL, headers:[String:String]? = nil, success:@escaping HTTPSuccessClosure, failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .delete,
                            headers: headers,
                            success: success,
                            failure: failure)
    }
    
    //MARK: - Utility
    
    ///Utilty method to create an automatically resumed data task given the input configuration.
    @discardableResult private func httpDataTask(with url:URL,
                                                 method:HTTPMethods,
                                                 headers:[String:String]? = nil,
                                                 contentType:HTTPContentType? = nil,
                                                 body:Data? = nil,
                                                 success:@escaping HTTPSuccessClosure,
                                                 failure:@escaping HTTPFailureClosure) -> URLSessionDataTask?
    {
        //method to handle internal result of success
        func dataTaskSuccessHandler(request:URLRequest?, data:Data?, response:HTTPURLResponse, error:Error?) {
            #if DUMP_NETWORK_RESULTS
                printResult(forRequest: request, data: data, response: response, error: error)
            #endif
            
            success(response, JSON(data: data ?? Data()))
        }
        
        //method to handle interal result of failure
        func dataTaskFailureHandler(request:URLRequest?, data:Data?, response:HTTPURLResponse?, error:Error?) {
            #if DUMP_NETWORK_RESULTS || DEBUG
                printResult(forRequest: request, data: data, response: response, error: error)
            #endif
            
            if let data = data, error == nil {
                failure(response, JSONSessionErrors.badHTTPResponse(data))
            } else {
                failure(response, error)
            }
        }
        
        //create request
        var request:URLRequest = URLRequest(url: url)
        
        //configure method
        request.httpMethod = method.rawValue
        
        //Add headers
        //content-type
        if let contentType = contentType {
            request.setValue(contentType.rawValue, forHTTPHeaderField: HTTPHeaders.contentType.rawValue)
        }
        
        //accept JSON in result
        request.setValue(HTTPContentType.applicationJSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        
        //additional (user defined) headers
        headers?.forEach { (key: String, value: String) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        //add body
        request.httpBody = body
        
        //create data task
        let httpDataTask:URLSessionDataTask = dataTask(with: request) { (data, response, error) in
            guard let httpResponse:HTTPURLResponse = response as? HTTPURLResponse else {
                dataTaskFailureHandler(request: request as URLRequest, data: data, response:nil, error: error)
                return
            }
            
            //because we are assuming RESTful style operation require a 2xx class response for success
            switch httpResponse.status {
            case .success:
                dataTaskSuccessHandler(request: request as URLRequest, data: data, response:httpResponse, error: error)
                
            default:
                dataTaskFailureHandler(request: request as URLRequest, data: data, response:httpResponse, error: error)
            }
        }
        
        httpDataTask.resume()
        
        return httpDataTask
    }
    
    ///Utility method to print response and error objects for debugging purposes
    fileprivate func printResult(forRequest request:URLRequest?, data:Data?, response:HTTPURLResponse?, error:Error?) {
        var result:String = ">>>>>>>>>>\n\n\(#file)\n\n"
        
        if let request = request {
            result += String("request: \(request)\n\n")
        }
        
        if let data = data {
            result += String("data: \(String(describing: String(data:data, encoding:.utf8)))\n\n")
        }
        
        if let response = response {
            result += String("response: \(response)\n\n")
        }
        
        if let error = error {
            result += String("error: \(error.localizedDescription)\n\n")
        }
        
        result += "<<<<<<<<<<"
        
        print(result)
    }
}
