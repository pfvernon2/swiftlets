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
        struct JSONTest: JSON {
            let string: String
            let int: Int
            let double: Double
            let date: Date
            let null: String?
            
            init() {
                self.string = "foobar"
                self.int = 42
                self.double = 5200.01
                self.date = Date(timeIntervalSince1970: 1514572592.0)
                self.null = nil
            }
        }
        
        guard let jsonString = JSONTest().toJSONString(prettyPrint: true) else {
            XCTFail()
            return
        }
        
        //test json string parsing
        guard let jsonTest:JSONTest = JSONTest.fromJSONString(jsonString) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(jsonTest.string, "foobar")
        XCTAssertEqual(jsonTest.int, 42)
        XCTAssertEqual(jsonTest.double, 5200.01)
        XCTAssertEqual(jsonTest.date, Date(timeIntervalSince1970: 1514572592.0))
        XCTAssertNil(jsonTest.null)
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
    //  http://ip.jsontest.com
    // Not really a unit test but oh well…
    func testJSONRequest() {
        struct JSONTestIP: JSON {
            let ip: String
        }
        
        let urlComponents:URLComponents? = URLComponents(scheme: .http, host: "ip.jsontest.com")
        guard let url:URL = urlComponents?.url else {
            XCTAssert(false)
            return
        }

        testGroup.enter()
        
        let session:URLSession = URLSession(configuration: .default)
        session.httpGet(with: url) { (response, json: JSONTestIP?, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(response)
            XCTAssertNotNil(json)
            self.testGroup.leave()
        }
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
    
    func testWriterReader() {
        var state:Bool = false
        let writerReader:DispatchWriterReader = DispatchWriterReader()
        
        let read1 = writerReader.read { () -> Bool in
            print("Read 1")
            return state
        }
        print(read1)
        XCTAssert(!read1)

        let read2 = writerReader.read { () -> Bool in
            print("Read 2")
            return state
        }
        XCTAssert(!read2)
        print(read2)

        testGroup.enter()
        DispatchQueue.global().asyncAfter(secondsFromNow: 0.5) {
            let read3 = writerReader.read { () -> Bool in
                print("Read 3")
                return state
            }
            print(read3)
            XCTAssert(read3)
            self.testGroup.leave()
        }
        
        print("About to write")
        writerReader.write {
            sleep(1)
            print("Write 1")
            state = true;
        }
    }
    
    func testDispatchGuard() {
        let guardian:DispatchGuard = DispatchGuard(value: 2)
        
        XCTAssert(guardian.enter())
        XCTAssert(guardian.enter())
        XCTAssertFalse(guardian.enter())

        guardian.exit()
        
        let custodian:DispatchGuardCustodian = DispatchGuardCustodian(guardian)
        XCTAssert(custodian.acquired)

        let custodian2:DispatchGuardCustodian = DispatchGuardCustodian(guardian)
        XCTAssertFalse(custodian2.acquired)
        
        guardian.exit()
    }
    
    func testStrings() {
        XCTAssert(String("00000").isLikeZipCode())
        XCTAssert(String("00000-0000").isLikeZipCode())
        XCTAssertFalse(String("0000-00000").isLikeZipCode())
        XCTAssertFalse(String("fubar-0000").isLikeZipCode())
        XCTAssertFalse(String("00000-fubr").isLikeZipCode())
        
        XCTAssert(String("foo@bar.com").isLikeEmailAddress())
        XCTAssertFalse(String("foobar.com").isLikeEmailAddress())
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
