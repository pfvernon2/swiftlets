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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testJSON() {
        let jsonString = "{\"string\":\"foo\",\"int\":500,\"double\":5200.0,\"date\":\"2016-10-26T16:39:52Z\"}"
        
        //test parsing
        let json:JSON = JSON(string: jsonString)
        XCTAssertEqual(json["string"].asString, "foo")
        XCTAssertEqual(json["int"].asInt, 500)
        XCTAssertEqual(json["double"].asDouble, 5200.0)
        XCTAssertEqual(json["date"].asDate, ISO8601DateFormatter().date(from: "2016-10-26T16:39:52Z"))
        
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
        print(json.toString(prettyPrint: true))
        XCTAssertTrue(floor(json["date"].asDate!.timeIntervalSinceReferenceDate) == floor(date.timeIntervalSinceReferenceDate))
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
