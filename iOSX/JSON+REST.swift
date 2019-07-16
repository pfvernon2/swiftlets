//
//  NSURLSession+JSON.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/22/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.

import Foundation

//MARK: - JSON Protocol

public protocol JSON:Codable {
    ///Returns default JSONEncoder. Override for custom configurations
    func jsonEncoder() -> JSONEncoder
    func toJSON() -> Data?
    func toJSONString(prettyPrint:Bool) -> String?
    
    ///Returns default JSONDecoder. Override for custom configurations
    static func jsonDecoder() -> JSONDecoder
    static func fromJSON<T:Decodable>(_ data:Data) -> T?
    static func fromJSONString<T:Decodable>(_ string:String) -> T?
}

extension JSON {
    ///Returns default JSONEncoder. Override for custom configurations
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
        
        if prettyPrint {
            encoder.outputFormatting = .prettyPrinted
        }
        
        guard let jsonData:Data = try? encoder.encode(self) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    ///Returns default JSONDecoder. Override for custom configurations
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

//MARK: - Result Extensions

extension Result {
    var isSuccess: Bool {
        get {
            switch self {
            case .success:
                return true
            default:
                return false
            }
        }
    }
}

extension Result where Success == Data {
    func json<T: JSON>() -> T? {
        guard let data = try? get() else {
            return nil
        }

        return T.fromJSON(data)
    }
}

//MARK: - NSURLSession Extensions

public extension URLSessionConfiguration {
    ///Sensible defaults for a REST style session
    class func RESTConfiguration(cachePolicy: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData) -> URLSessionConfiguration {
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
        config.requestCachePolicy = cachePolicy
        
        return config
    }
}

//MARK: - URLSession Extensions

public extension URLSession {
    enum JSONSessionErrors: Error {
        case invalidQueryItem(String)
        case requestFailed(HTTPURLResponse)
        case error(Error)
        case unknown
    }
    
    enum HTTPHeaders:String {
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
     
     - note: It is guaranteed that the completion closure will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - Parameter url: The url of the request
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter completion: A closure to be called on success or failure.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpGet(with url:URL, headers:[String:String]? = nil, completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .get,
                            headers: headers,
                            completion: completion)
    }

    //MARK: - Put
    
    /**
     Perform PUT request with a JSON payload
     
     - note: It is guaranteed that the completion closure will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.

     - Parameter url: The url of the request
     - Parameter bodyJSON: A JSON object to included as the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter completion: A closure to be called on success or failure.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPut(with url:URL, bodyJSON:JSON? = nil, headers:[String:String]? = nil, completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        let bodyJSONData:Data? = bodyJSON?.toJSON()
        
        return httpDataTask(with: url,
                            method: .put,
                            headers: headers,
                            contentType: .applicationJSON,
                            body: bodyJSONData,
                            completion: completion)
    }
    
    /**
     Perform PUT request with a URL parameter payload
     
     - note: It is guaranteed that the completion closure will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.

     - Parameter url: The url of the request
     - Parameter bodyParameters: An array of NSURLQueryItem objects to be escaped and included in the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter completion: A closure to be called on success or failure.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPut(with url:URL, bodyParameters:[URLQueryItem], headers:[String:String]? = nil, completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        guard let body:String = URLQueryItem.REST_urlEscapedDescription(queryItems: bodyParameters) else {
            completion(.failure(JSONSessionErrors.invalidQueryItem(bodyParameters.description)))
            return nil
        }
        
        return httpDataTask(with: url,
                            method: .post,
                            contentType: .formURLEncoded,
                            body: body.data(using: .utf8),
                            completion: completion)
    }
    
    //MARK: - Post
    
    /**
     Perform POST request with a JSON payload
     
     - note: It is guaranteed that the completion closure will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.

     - Parameter url: The url of the request
     - Parameter bodyJSON: A JSON object to included as the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter completion: A closure to be called on success or failure.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPost(with url:URL, bodyJSON:JSON? = nil, headers:[String:String]? = nil, completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        let bodyJSONData:Data? = bodyJSON?.toJSON()
        
        return httpDataTask(with: url,
                            method: .post,
                            headers: headers,
                            contentType: .applicationJSON,
                            body: bodyJSONData,
                            completion: completion)
    }
    
    /**
     Perform POST request with a URL parameter payload
     
     - note: It is guaranteed that the completion closure will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.

     - Parameter url: The url of the request
     - Parameter bodyParameters: An array of NSURLQueryItem objects to be escaped and included in the body of the post
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter completion: A closure to be called on success or failure.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpPost(with url:URL, bodyParameters:[URLQueryItem], headers:[String:String]? = nil, completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        guard let body:String = URLQueryItem.REST_urlEscapedDescription(queryItems: bodyParameters) else {
            completion(.failure(JSONSessionErrors.invalidQueryItem(bodyParameters.description)))
            return nil
        }
        
        return httpDataTask(with: url,
                            method: .post,
                            contentType: .formURLEncoded,
                            body: body.data(using: .utf8),
                            completion: completion)
    }
    
    //MARK: - Delete
    
    /**
     Perform DELETE request
     
     - note: It is guaranteed that the completion closure will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.

     - Parameter url: The url of the request
     - Parameter headers: Additional headers for the request, if necessary.
     - Parameter completion: A closure to be called on success or failure.
     - returns: NSURLSessionDataTask already resumed
     */
    @discardableResult func httpDelete(with url:URL, headers:[String:String]? = nil, completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        return httpDataTask(with: url,
                            method: .delete,
                            headers: headers,
                            completion: completion)
    }
    
    //MARK: - Utility
    
    ///Utilty method to create an automatically resumed data task given the input configuration.
    @discardableResult private func httpDataTask(with url:URL,
                                                 method:HTTPMethods,
                                                 headers:[String:String]? = nil,
                                                 contentType:HTTPContentType? = nil,
                                                 body:Data? = nil,
                                                 completion:@escaping (Result<Data, JSONSessionErrors>) -> Swift.Void) -> URLSessionDataTask?
    {
        //method to handle internal result of success
        func dataTaskSuccessHandler(request:URLRequest?, data:Data?, response:HTTPURLResponse, error:Error?) {
            guard let data = data else {
                completion(.failure(JSONSessionErrors.requestFailed(response)))
                return
            }

            completion(.success(data))
        }
        
        //method to handle interal result of failure
        func dataTaskFailureHandler(request:URLRequest?, data:Data?, response:HTTPURLResponse?, error:Error?) {
            switch (response, error) {
            case (.some(let response), .some):
                completion(.failure(JSONSessionErrors.requestFailed(response)))
            case (.some(let response), .none):
                completion(.failure(JSONSessionErrors.requestFailed(response)))
            case (.none, .some(let error)):
                completion(.failure(JSONSessionErrors.error(error)))
            default:
                completion(.failure(JSONSessionErrors.unknown))
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
            #if DUMP_NETWORK_RESULTS || DEBUG
            printResult(forRequest: request, data: data, response: response, error: error)
            #endif

            guard let httpResponse:HTTPURLResponse = response as? HTTPURLResponse else {
                dataTaskFailureHandler(request: request as URLRequest, data: data, response:nil, error: error)
                return
            }
            
            //because we are assuming RESTful style operation require a 2xx class response for success
            switch httpResponse.statusCode {
            case 200..<300:
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

extension String.StringInterpolation {
    mutating func appendInterpolation(_ jsonSessionError: URLSession.JSONSessionErrors) {
        switch jsonSessionError {
        case .invalidQueryItem(let query):
            appendInterpolation(NSLocalizedString("Invalid Query: \(query)",
                comment: "URLSession Error - invalid query"))

        case .requestFailed(let response):
            appendInterpolation(NSLocalizedString("Request Failure: \(response.status) (\(response.statusCode))",
                comment: "URLSession Error - request failure"))

        case .error(let error):
            appendInterpolation(NSLocalizedString("Error: \(error)",
                comment: "URLSession Error - error"))

        case .unknown:
            appendInterpolation(NSLocalizedString("Unknown error",
                                                  comment: "URLSession Error - unknown error"))
        }
    }
}

//MARK: - fileprivate extensions
// Duplicated from URLComponenets+Utilites for the sake of file portability

fileprivate extension NSCharacterSet {
    static let REST_urlQueryItemParamAndValueAllowed:CharacterSet = {
        var allowedQueryParamAndKey = NSCharacterSet.urlQueryAllowed
        allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$, ")
        return allowedQueryParamAndKey
    }()
}

fileprivate extension URLQueryItem {
    ///Utility method to return the URL Query Item description with the name and value escaped for use in a URL query
    func REST_urlEscapedDescription() -> String? {
        guard let encodedName = self.name.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.REST_urlQueryItemParamAndValueAllowed) else {
            return nil
        }
        
        guard let encodedValue = self.value?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.REST_urlQueryItemParamAndValueAllowed) else {
            return nil
        }
        
        return "\(encodedName) = \(encodedValue)"
    }
    
    static func REST_urlEscapedDescription(queryItems:[URLQueryItem]) -> String? {
        return queryItems.compactMap { (queryItem) -> String? in
            return queryItem.REST_urlEscapedDescription()
            }.joined(separator: "&")
    }
}

