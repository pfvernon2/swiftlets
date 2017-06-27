//
//  NSURLSession+JSON.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.

import Foundation

//MARK: - JSON Protocol

public protocol JSON:Codable {
    func jsonEncoder() -> JSONEncoder
    func toJSON() -> Data?
    func toJSONString(prettyPrint:Bool) -> String?
    
    static func jsonDecoder() -> JSONDecoder
    static func fromJSON<T:Decodable>(_ data:Data) -> T?
    static func fromJSONString<T:Decodable>(_ string:String) -> T?
}

extension JSON {
    func jsonEncoder() -> JSONEncoder {
        return JSONEncoder()
    }
    
    func toJSON() -> Data? {
        return try? jsonEncoder().encode(self)
    }
    
    func toJSONString(prettyPrint:Bool) -> String? {
        let encoder:JSONEncoder = jsonEncoder()
        let originalFormatting = encoder.outputFormatting
        defer {
            encoder.outputFormatting = originalFormatting
        }
        
        encoder.outputFormatting = prettyPrint ? .prettyPrinted : .compact
        guard let jsonData:Data = try? encoder.encode(self) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    static func jsonDecoder() -> JSONDecoder {
        return JSONDecoder()
    }
    
    static func fromJSON<T:Decodable>(_ data:Data) -> T? {
        let result:T? = try? jsonDecoder().decode(T.self, from: data)
        return result
    }
    
    static func fromJSONString<T:Decodable>(_ string:String) -> T? {
        guard let data:Data = string.data(using: .utf8, allowLossyConversion: true) else {
            return nil
        }
        return fromJSON(data)
    }
}

//MARK: - NSURLSession Extensions

public extension URLSessionConfiguration {
    ///Sensible defaults for a REST style session
    public class func RESTConfiguration() -> URLSessionConfiguration {
        let config:URLSessionConfiguration = URLSessionConfiguration.default
        
        #if os(iOS)
            let osType:String = "iOS"
        #elseif os(tvOS)
            let osType:String = "tvOS"
        #elseif os(watchOS)
            let osType:String = "watchOS"
        #elseif os(macOS)
            let osType:String = "macOS"
        #elseif os(Linux)
            let osType:String = "Linux"
        #else
            let osType:String = "Unknown"
        #endif
        config.httpAdditionalHeaders = ["User-Agent": "\(osType); REST client"]
        
        config.timeoutIntervalForRequest = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        return config
    }
}

//MARK: - URLSession Extensions

public extension URLSession {
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
    @discardableResult func httpGet<T:JSON>(with url:URL, headers:[String:String]? = nil, success:@escaping (HTTPURLResponse, T?) -> Swift.Void, failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
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
    @discardableResult func httpPut<T:JSON>(with url:URL, bodyJSON:JSON? = nil, headers:[String:String]? = nil, success:@escaping (HTTPURLResponse, T?) -> Swift.Void, failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
    {
        let bodyJSONData:Data? = bodyJSON?.toJSON()
        
        return httpDataTask(with: url,
                            method: .put,
                            headers: headers,
                            contentType: .applicationJSON,
                            body: bodyJSONData,
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
    @discardableResult func httpPut<T:JSON>(with url:URL, bodyParameters:[URLQueryItem], headers:[String:String]? = nil, success:@escaping (HTTPURLResponse, T?) -> Swift.Void, failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
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
    @discardableResult func httpPost<T:JSON>(with url:URL, bodyJSON:JSON? = nil, headers:[String:String]? = nil, success:@escaping (HTTPURLResponse, T?) -> Swift.Void, failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
    {
        let bodyJSONData:Data? = bodyJSON?.toJSON()
        
        return httpDataTask(with: url,
                            method: .post,
                            headers: headers,
                            contentType: .applicationJSON,
                            body: bodyJSONData,
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
    @discardableResult func httpPost<T:JSON>(with url:URL, bodyParameters:[URLQueryItem], headers:[String:String]? = nil, success:@escaping (HTTPURLResponse, T?) -> Swift.Void, failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
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
    @discardableResult func httpDelete<T:JSON>(with url:URL, headers:[String:String]? = nil, success:@escaping (HTTPURLResponse, T?) -> Swift.Void, failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .delete,
                            headers: headers,
                            success: success,
                            failure: failure)
    }
    
    //MARK: - Utility
    
    ///Utilty method to create an automatically resumed data task given the input configuration.
    @discardableResult private func httpDataTask<T:JSON>(with url:URL,
                                                 method:HTTPMethods,
                                                 headers:[String:String]? = nil,
                                                 contentType:HTTPContentType? = nil,
                                                 body:Data? = nil,
                                                 success:@escaping (HTTPURLResponse, T?) -> Swift.Void,
                                                 failure:@escaping (HTTPURLResponse? , Error?) -> Swift.Void) -> URLSessionDataTask?
    {
        //method to handle internal result of success
        func dataTaskSuccessHandler(request:URLRequest?, data:Data?, response:HTTPURLResponse, error:Error?) {
            #if DUMP_NETWORK_RESULTS
                printResult(forRequest: request, data: data, response: response, error: error)
            #endif
            
            let result:T? = T.fromJSON(data ?? Data())
            success(response, result)
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
        headers?.forEach { (__val:(String, String)) in let (key,value) = __val; 
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
        var result:String = "⚠️\n\n\(#file)\n\n"
        
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
        
        result += "⚠️"
        
        print(result)
    }
}
