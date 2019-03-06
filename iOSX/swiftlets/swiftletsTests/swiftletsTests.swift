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
        var pathComponents:POSIXPathComponents = POSIXPathComponents(path: pathString)
        XCTAssert(pathComponents.isAbsolute)
        XCTAssert(pathComponents.isLeaf)
        XCTAssert(pathComponents.components.count == 5)
        XCTAssert(pathComponents.description == pathString)
        
        pathComponents.isLeaf = !pathComponents.isLeaf
        XCTAssert(pathComponents.description != pathString)

        pathComponents.append(pathComponents: POSIXPathComponents(path:"//6//"))
        XCTAssert(pathComponents.components.count == 6)
        
        //edge case - root directory
        let rootPathString:String = "/"
        let rootDirectory:POSIXPathComponents = POSIXPathComponents(path: rootPathString)
        XCTAssert(rootDirectory.isAbsolute)
        XCTAssert(!rootDirectory.isLeaf)
        XCTAssert(rootDirectory.description == rootPathString)
        
        //path built from empty struct
        var emptyPath:POSIXPathComponents = POSIXPathComponents()
        emptyPath.append(path: pathString)
        XCTAssert(emptyPath.isAbsolute)
        XCTAssert(emptyPath.isLeaf)
        XCTAssert(emptyPath.components.count == 5)
        XCTAssert(emptyPath.description == pathString)
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
            defer {
                self.testGroup.leave()
            }

            guard error == nil,
                let response = response,
                let json = json,
                let prettyJSON:String = json.toJSONString(prettyPrint: true) else {
                    print("3rd party JSON testing service is most likely down.")
                    XCTFail()
                    return
            }

            XCTAssert(response.status.isSuccess())
            XCTAssert(json.ip.isLikeIPV4Address())
            print(prettyJSON)
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
        XCTAssertFalse(String("00000-000").isLikeZipCode())
        XCTAssertFalse(String("0000-0000").isLikeZipCode())
        XCTAssertFalse(String("0000-00000").isLikeZipCode())
        XCTAssertFalse(String("fubar-0000").isLikeZipCode())
        XCTAssertFalse(String("00000-fubr").isLikeZipCode())
        
        XCTAssert(String("foo@bar.com").isLikeEmailAddress())
        XCTAssertFalse(String("foobar.com").isLikeEmailAddress())
        
        XCTAssert(String("1.1.1.1").isLikeIPV4Address())
        XCTAssertFalse(String("1.1.1.").isLikeIPV4Address())
        XCTAssertFalse(String("1.1.1.512").isLikeIPV4Address())

        let osType:FourCharCode = "AAPL"
        XCTAssertEqual(osType, 0x4141504C)
        XCTAssertEqual(osType.string, "AAPL")
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    
    func testMisc() {
        //test CGPoint snap() extension
        let testPoint: CGPoint = CGPoint(x: 100.4, y: 100.6)
        
        let upperLeft: CGPoint = CGPoint(x: 100.0, y: 101.0)
        let upperRight: CGPoint = CGPoint(x: 101.0, y: 101.0)
        let lowerLeft: CGPoint = CGPoint(x: 100.0, y: 100.0)
        let lowerRight: CGPoint = CGPoint(x: 101.0, y: 100.0)
        let nearest: CGPoint = CGPoint(x: 100.0, y: 101.0)
        
        var temp = testPoint;
        temp.snap(to: .upperLeft);
        XCTAssert(temp == upperLeft)
        
        temp = testPoint;
        temp.snap(to: .upperRight);
        XCTAssert(temp == upperRight)

        temp = testPoint;
        temp.snap(to: .lowerLeft);
        XCTAssert(temp == lowerLeft)

        temp = testPoint;
        temp.snap(to: .lowerRight);
        XCTAssert(temp == lowerRight)

        temp = testPoint;
        temp.snap(to: .nearest);
        XCTAssert(temp == nearest)
        
        //Test CGSize max/min dimension
        let testSize: CGSize = CGSize(width: 100.0, height: 200.0)
        XCTAssert(testSize.maxDimension() == 200.0)
        XCTAssert(testSize.minDimension() == 100.0)

        //test byte extraction
        let bigInteger: UInt64 = 0x0001020304050607
        let bytes = bigInteger.bytes
        XCTAssertEqual(bytes, [0, 1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(bigInteger[6], 0x06)
    }
    
    func testColor() {
        let red:String = "FF0000"
        let redAlpha:String = "#ff0000ff"
        
        let redColor:UIColor? = red.colorForHex()
        XCTAssertNotNil(redColor)
        
        let redAlphaColor:UIColor? = redAlpha.colorForHex()
        XCTAssertNotNil(redAlphaColor)
        
        let bad:String = "xxxxxx"
        let badColor:UIColor? = bad.colorForHex()
        XCTAssertNil(badColor)
        
        let color:UIColor? = UIColor(htmlHex: redAlpha)
        XCTAssertNotNil(color)
        let colorComponents:[CGFloat]? = color?.cgColor.components
        XCTAssertNotNil(colorComponents)
        XCTAssert(colorComponents![0] == 1.0)
        XCTAssert(colorComponents![1] == 0.0)
        XCTAssert(colorComponents![2] == 0.0)
        XCTAssert(colorComponents![3] == 1.0)
    }

    func testCSV() {
        let tempFile = FileManager.default.temporaryFile

        let writeTest:[[String]] = [
            ["#", "A", "B", "C", "D"],
            ["1", "A,1", "B,1", "C,1", "D,1"],
            ["2", "A\"2", "B\"2", "C\"2", "D\"2"],
            ["3", "A3", "B3", "C3", "D3"],
            ["4", "A4", "B4", "C4", "D4"],
            ]
        CSVHelper.write(writeTest, toFile: tempFile)

        let readTest = CSVHelper.read(contentsOfURL: tempFile)
        XCTAssert(readTest == writeTest)
    }

    func testData() {
        var stringData:Data = Data()
        stringData.appendStringAsUTF8("foobar");
        XCTAssertEqual(stringData.hexRepresentation(), "666F6F626172")
    }

    func testDate() {
        //extended precision 8601
        let testString:String = "1965-11-13T13:07:36.639Z"
        guard let testDate:Date = DateFormatter.tryParseISO8601LikeDateString(testString) else {
            XCTFail()
            return
        }
        XCTAssertEqual(testDate, Date(timeIntervalSince1970: -130391543.36100006))

        //relative date string, test assumes system locale is english
        guard let relativity:String = DateFormatter.relativeDateTimeString(from: Date(timeIntervalSinceNow: 60.0 * 60.0 * 24.0),
                                                                     dateStyle: .medium,
                                                                     timeStyle: .none) else {
                                                                        XCTFail()
                                                                        return
        }
        XCTAssertEqual(relativity, "Tomorrow")
    }
}
