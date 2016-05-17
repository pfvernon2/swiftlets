//
//  NSURLSession+JSON.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension NSURLComponents {
    /**
     A convenience var to allow getting and setting the query component of HTTP URL parameters via a [String,String] dictionary.
     */

    var queryParameters:[String:String]? {
        set {
            if let parameters = queryParameters {
                self.query = queryParametersFromDictionary(parameters)
            } else {
                self.query = nil
            }
        }
        get {
            return queryDictionaryFromParameters(self.query)
        }
    }
    
    /**
     Utility method to convert a query parameter string of a HTTP URL to a [String,String] dictionary
     
     - parameters:
         - parameters: a string query parameters from a URL
     - returns: A [String,String] dictionary of query parameters
     */

    func queryDictionaryFromParameters(parameters:String?) -> [String:String] {
        //TODO: [A miracle, probably involving NSScanner, happens here]
        return [:]
    }

    /**
     Utility method to convert a [String,String] dictionary to the query component of a HTTP URL
     
     - parameters:
         - parameters: a [String,String] dictionary of query parameters to the URL
     - returns: String representation suitable for assigning to the query component
     */

    func queryParametersFromDictionary(parameters:[String:String]) -> String {
        var result:String = String()
        
        for (key,value) in parameters {
            if result.isEmpty {
                result = result + "?"
            } else {
                result = result + "&"
            }
            
            result = result + String(format: "%@=%@", key, value)
        }
        
        return result
    }
}

extension NSURLSession {
    
    /**
     Post JSON dictionary via HTTP to a URL and expect a JSON result in the response.
     
     - note: This is merely a type explicit wrapper of the json:AnyObject? version
     
     - parameters:
         - baseURL: The base URL including the HTTP(S) protocol
         - path: A path to append to the base URL
         - parameters: A dictionary of key value pairs for the parameter section of the URL.
         - jsonDictionary: A dictionary containing JSON data for the body of the post
         - success: A closure to be called on success. The NSURLResponse and a JSON object may be included.
         - failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask ready to be resumed
     */

    func httpPost(baseURL:String, path:String?, parameters:[String:String]?, jsonDictionary:[String:AnyObject]?, success:(NSURLResponse?, AnyObject?) -> Void, failure:(NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return httpPost(baseURL, path: path, parameters: parameters, json: jsonDictionary, success: success, failure: failure)
    }
    
    /**
     Post JSON array via HTTP to a URL and expect a JSON result in the response
     
     - note: This is merely a type explicit wrapper of the json:AnyObject? version

     - parameters:
         - baseURL: The base URL including the HTTP(S) protocol
         - path: A path to append to the base URL
         - parameters: A dictionary of key value pairs for the parameter section of the URL.
         - jsonDictionary: A dictionary containing JSON data for the body of the post
         - success: A closure to be called on success. The NSURLResponse and a JSON object may be included.
         - failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask ready to be resumed
     */
    
    func httpPost(baseURL:String, path:String?, parameters:[String:String]?, jsonArray:[AnyObject]?, success:(NSURLResponse?, AnyObject?) -> Void, failure:(NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return httpPost(baseURL, path: path, parameters: parameters, json: jsonArray, success: success, failure: failure)
    }

    /**
     Post JSON object via HTTP to a URL and expect a JSON result in the response
     
     - parameters:
         - baseURL: The base URL including the HTTP(S) protocol
         - path: A path to append to the base URL
         - parameters: A dictionary of key value pairs for the parameter section of the URL.
         - jsonDictionary: A dictionary containing JSON data for the body of the post
         - success: A closure to be called on success. The NSURLResponse and a JSON object may be included.
         - failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask ready to be resumed
     */

    func httpPost(baseURL:String, path:String?, parameters:[String:String]?, json:AnyObject?, success:(NSURLResponse?, AnyObject?) -> Void, failure:(NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        
        var data:NSData = NSData()
        if let json = json {
            do {
                data = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
            } catch let error as NSError {
                failure(nil, error)
                return nil
            }
        }
        
        return httpPost(baseURL, path: path, parameters: parameters, data: data, success: success, failure: failure)
    }

    /**
     Post data via HTTP to a URL and expect a JSON result in the response
     
     - parameters:
         - baseURL: The base URL including the HTTP(S) protocol
         - path: A path to append to the base URL
         - parameters: A dictionary of key value pairs for the parameter section of the URL.
         - jsonDictionary: A dictionary containing JSON data for the body of the post
         - success: A closure to be called on success
         - failure: A closure to be called on failure
     - returns: NSURLSessionDataTask ready to be resumed
     */
    func httpPost(baseURL:String, path:String?, parameters:[String:String]?, data:NSData?, success:(NSURLResponse?, AnyObject?) -> Void, failure:(NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask?
    {
        if let url:NSURLComponents = NSURLComponents(string: baseURL) {
            if let path = path {
                url.path = path
            }

            if let parameters = parameters {
                url.queryParameters = parameters
            }
            
            if let url = url.URL {
                if let request:NSMutableURLRequest = NSMutableURLRequest(URL: url) {
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    request.HTTPMethod = "POST"
                    
                    return dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                        if let error = error {
                            failure(nil, error)
                        } else if let data = data {
                            do {
                                let result = try NSJSONSerialization.JSONObjectWithData(data, options: [.MutableLeaves, .MutableContainers])
                                success(response, result)
                            } catch let error as NSError {
                                failure(response, error)
                            }
                        } else {
                            failure(response, nil)
                        }
                    })
                } else {
                    failure(nil, NSError(domain: "NSURLSession.httpPost.badRequest", code: 0, userInfo: nil))
                    return nil
                }
            } else {
                failure(nil, NSError(domain: "NSURLSession.httpPost.badURL", code: 0, userInfo: nil))
                return nil
            }
        } else {
            failure(nil, NSError(domain: "NSURLSession.httpPost.badURL", code: 0, userInfo: nil))
            return nil
        }
    }
}