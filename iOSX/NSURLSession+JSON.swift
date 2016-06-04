//
//  NSURLSession+JSON.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension NSHTTPURLResponse {
    func isOK() -> Bool {
        return statusCode == 200
    }

    func isSuccess() -> Bool {
        return statusCode >= 200 && statusCode < 300
    }
}

private let kHTTPPostMethod:String = "POST"
private let kHTTPGetMethod:String = "GET"
private let kHTTPAcceptHeader:String = "Accept"
private let kHTTPContentTypeHeader:String = "Content-Type"
private let kHTTPContentTypeJSON:String = "application/json"
private let kHTTPContentTypeFormURLEncoded:String = "application/x-www-form-urlencoded"

public typealias HTTPJSONSuccessClosure = (NSHTTPURLResponse, JSON) -> Void
public typealias HTTPFailureClosure = (NSHTTPURLResponse?, NSError?) -> Void

public extension NSURLSession {

    //MARK: - Get

    /**
     Perform GET request and expect JSON result in response.
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - parameters:
         - url: The url of the request
         - success: A closure to be called on success. The NSURLResponse and a JSON object may be included.
         - failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */

    func httpGet(url:NSURL, success:HTTPJSONSuccessClosure, failure:HTTPFailureClosure) -> NSURLSessionDataTask?
    {
        return httpDataTask(url,
                            method: kHTTPGetMethod,
                            contentType: nil,
                            body: nil,
                            success: success,
                            failure: failure);
    }

    //MARK: - POST

    /**
     Perform POST request with a JSON payload and expect JSON result in response.
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.

     - parameters:
         - url: The url of the request
         - bodyJSON: An optional JSON object to included as the body of the post
         - success: A closure to be called on success. The NSURLResponse and a JSON object may be included.
         - failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */

    func httpPost(url:NSURL, bodyJSON:JSON?, success:HTTPJSONSuccessClosure, failure:HTTPFailureClosure) -> NSURLSessionDataTask?
    {
        let data:NSData? = bodyJSON?.toData()
        
        return httpDataTask(url,
                            method: kHTTPPostMethod,
                            contentType: kHTTPContentTypeJSON,
                            body: data,
                            success: success,
                            failure: failure);
    }
    
    /**
     Perform POST request with a URL parameter payload and expect JSON result in response.
     
     - note: It is guaranteed that exactly one of the success or failure closures will be invoked after this method is called regardless of whether a valid NSURLSessionDataTask is returned.
     
     - parameters:
         - url: The url of the request
         - bodyParameters: An optional array of NSURLQueryItem to be escaped and included in the body of the post
         - success: A closure to be called on success. The NSURLResponse and a JSON object may be included.
         - failure: A closure to be called on failure. The NSURLResponse and an error may be included.
     - returns: NSURLSessionDataTask already resumed
     */

    func httpPost(url:NSURL, bodyParameters:[NSURLQueryItem]?, success:HTTPJSONSuccessClosure, failure:HTTPFailureClosure) -> NSURLSessionDataTask?
    {
        var body:String = ""
        for queryItem:NSURLQueryItem in bodyParameters! {
            if let escapedItem = queryItem.urlEscapedItem() {
                if !body.isEmpty {
                    body = body + "&" + escapedItem
                } else {
                    body = escapedItem
                }
            }
        }
        let data:NSData? = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        return httpDataTask(url,
                            method: kHTTPPostMethod,
                            contentType: kHTTPContentTypeFormURLEncoded,
                            body: data,
                            success: success,
                            failure: failure);
    }
    
    //MARK: - Utility

    private func httpDataTask(url:NSURL,
                      method:String,
                      contentType:String?,
                      body:NSData?,
                      success:HTTPJSONSuccessClosure,
                      failure:HTTPFailureClosure) -> NSURLSessionDataTask?
    {
        //ensure request is valid
        guard let request:NSMutableURLRequest = NSMutableURLRequest(URL: url) else {
            failure(nil, NSError(domain: "NSURLSession.httpPost.badRequest", code: 0, userInfo: nil))
            return nil
        }
        
        //configure content-type
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: kHTTPContentTypeHeader)
        }

        //configure request to expect JSON result
        request.setValue(kHTTPContentTypeJSON, forHTTPHeaderField: kHTTPAcceptHeader)
        
        //configure method
        request.HTTPMethod = method
        
        //add body, if appropriate
        if let body = body {
            request.HTTPBody = body
        }
        
        //create data task
        let dataTask = dataTaskWithRequest(request) { (data, response, error) in
            if let response = response as? NSHTTPURLResponse {
                if response.isSuccess() {
                    success(response, JSON(data: data ?? NSData()))
                } else {
                    failure(response, error)
                }
            }
            else {
                failure(nil, error)
            }
        }
        
        //resume task
        dataTask.resume();
        
        return dataTask
    }
}