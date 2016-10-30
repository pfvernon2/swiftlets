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
        let jsonString = "{\"string\":\"foo\",\"int\":500,\"double\":5200.0}"
        
        //test parsing
        let json:JSON = JSON(string: jsonString)
        XCTAssertEqual(json["string"].asString, "foo")
        XCTAssertEqual(json["int"].asInt, 500)
        XCTAssertEqual(json["double"].asDouble, 5200.0)
        
        //test mutability
        json["string"] = JSON("bar")
        XCTAssertNotEqual(json["string"].asString, "foo")
        XCTAssertEqual(json["string"].asString, "bar")

        //test nilability
        json["int"] = JSON(nil)
        XCTAssert(json["int"].isNull)
        
        //test Date JSONTransformable protocol
        let date:Date = Date()
        json["date"] = JSON(date)
        XCTAssertTrue(floor(json["date"].asDate!.timeIntervalSinceReferenceDate) == floor(date.timeIntervalSinceReferenceDate))
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
