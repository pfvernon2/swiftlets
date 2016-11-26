//
//  swiftletsTests.swift
//  swiftletsTests
//
//  Created by Frank Vernon on 3/19/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import XCTest
@testable import swiftlets

class swiftletsTests: XCTestCase {
    let testGroup:DispatchGroup = DispatchGroup()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        testGroup.wait()
        
        super.tearDown()
    }
    
    func testJSON() {
        let jsonString = "{\"string\":\"foobar\",\"int\":42,\"double\":5200.01}"
        
        //test json string parsing
        let json:JSON = JSON(string: jsonString)
        XCTAssertEqual(json["string"].asString, "foobar")
        XCTAssertEqual(json["int"].asInt, 42)
        XCTAssertEqual(json["double"].asDouble, 5200.01)
        
        //test mutability
        json["string"] = JSON("barfoo")
        XCTAssertNotEqual(json["string"].asString, "foobar")
        XCTAssertEqual(json["string"].asString, "barfoo")

        //test nilability
        json["int"] = JSON(nil)
        XCTAssert(json["int"].isNull)
        
        //test Date JSONTransformable protocol
        let date:Date = Date()
        json["date"] = JSON(date)
        guard let jsonDate:Date = json["date"].asDate else {
            XCTAssert(false)
            return
        }
        //8601 conversion drops subsecond precision so simply ensure they are the same to the second
        XCTAssertTrue(Calendar.current.compare(date, to: jsonDate, toGranularity: .second) == .orderedSame)
        
        //test heterogeneous array unwrapping
        let values:[Any] = [1,"a",date]
        json["array"] = JSON(values)
        XCTAssertTrue(json["array"].isArray)
        XCTAssertTrue(json["array"].asArray?.count == values.count)
        guard let jsonArray = json["array"].asArray, jsonArray.count == values.count else {
            XCTAssert(false)
            return
        }
        XCTAssertTrue(jsonArray[0].isNumber)
        XCTAssertTrue(jsonArray[1].isString)
        XCTAssertTrue(jsonArray[2].isDate)

        //test heterogeneous dictionary unwrapping
        let dictionary:[String:Any] = ["1":1,"a":"a","Date":date]
        json["dictionary"] = JSON(dictionary)
        XCTAssertTrue(json["dictionary"].isDictionary)
        guard let jsonDictionary = json["dictionary"].asDictionary, jsonDictionary.count == values.count else {
            XCTAssert(false)
            return
        }
        XCTAssertTrue(jsonDictionary["1"]?.isNumber ?? false)
        XCTAssertTrue(jsonDictionary["a"]?.isString ?? false)
        XCTAssertTrue(jsonDictionary["Date"]?.isDate ?? false)
        
        print(json.toString(prettyPrint: true))
    }
    
    func testPathComponents() {
        //common use case
        let pathString:String = "/1/2/3/4/5"
        var pathComponents:UnixPathComponents = UnixPathComponents(path: pathString)
        XCTAssert(pathComponents.isFullyQualified)
        XCTAssert(pathComponents.isLeaf)
        XCTAssert(pathComponents.components.count == 5)
        XCTAssert(pathComponents.description == pathString)
        
        pathComponents.isLeaf = !pathComponents.isLeaf
        XCTAssert(pathComponents.description != pathString)

        pathComponents.append(pathComponents: UnixPathComponents(path:"//6//"))
        XCTAssert(pathComponents.components.count == 6)
        
        //edge case - root directory
        let rootPathString:String = "/"
        let rootDirectory:UnixPathComponents = UnixPathComponents(path: rootPathString)
        XCTAssert(rootDirectory.isFullyQualified)
        XCTAssert(!rootDirectory.isLeaf)
        XCTAssert(rootDirectory.description == rootPathString)
    }
    
    //Test using jsontest.com json validation method
    //  http://echo.jsontest.com/?json={"key":"value"}
    // Not really a unit test but oh well…
    func testJSONRequest() {
        var urlComponents:URLComponents? = URLComponents(scheme: .http, host: "echo.jsontest.com")
        let queryItem:URLQueryItem = URLQueryItem(name:"json", value:"{\"key\":\"value\"}")
        urlComponents?.append(queryParameterComponents:[queryItem])
        
        guard let url:URL = urlComponents?.url else {
            XCTAssert(false)
            return
        }

        testGroup.enter()
        
        let session:URLSession = URLSession(configuration: .default)
        session.httpGet(with: url,
                        success: { (response, json) in
                            XCTAssert(json.count > 0)
                            self.testGroup.leave()
            },
                        failure: { (response , error)  in
                            XCTAssert(false)
                            self.testGroup.leave()
            })
    }
    
    func testHTTPResult() {
        let httpResult = HTTPURLReponseStatus(statusCode: 200)
        
        switch httpResult {
        case .success(let successStatus):
            switch successStatus {
            case .ok:
                XCTAssert(true)
                
            default:
                XCTAssert(false)
            }
            
        default:
            XCTAssert(false)
        }
    }
    
    func testCachedImage() {
        guard let imageURL:URL = URL(string: "http://i.imgur.com/a97SL24.jpg") else {
            XCTAssert(false)
            return
        }
        
        let imageCache:RemoteImageCache = RemoteImageCache(cacheName: imageURL.host)
        
        testGroup.enter()
        
        imageCache.cachedImage(fromURL: imageURL) { image in
            XCTAssert(image != nil)
            imageCache.cachedImage(fromURL: imageURL) { image in
                XCTAssert(image != nil)
                self.testGroup.leave()
            }
        }
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
