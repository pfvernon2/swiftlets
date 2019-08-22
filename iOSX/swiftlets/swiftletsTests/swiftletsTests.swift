//
//  swiftletsTests.swift
//  swiftletsTests
//
//  Created by Frank Vernon on 3/19/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import XCTest
#if os(iOS)
@testable import swiftlets
#else
@testable import swiftlets_macos
#endif

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
    // Not really a unit test, and failures are common, but oh well…
    func testJSONRequest() {
        //expected JSON result format
        class JSONTestIP: JSON {
            let ip: String
        }

        //create REST style URLSession
        let session = URLSession(configuration: URLSessionConfiguration.RESTConfiguration())

        //create http request
        let urlComponents:URLComponents? = URLComponents(scheme: .http,
                                                         host: "ip.jsontest.com")
        guard let url:URL = urlComponents?.url else {
            XCTAssert(false)
            return
        }

        //test REST request with JSON payload in response
        testGroup.enter()
        session.httpGet(with: url) { result in
            defer {
                self.testGroup.leave()
            }

            guard result.isSuccess else {
                self.printFailure("\(result)")
                XCTFail()
                return
            }
            
            guard let json:JSONTestIP = result.json(),
                let prettyJSON:String = json.toJSONString(prettyPrint: true) else {
                    self.printFailure("JSON parsing error")
                    XCTFail()
                    return
            }

            print("JSON response:\n\(prettyJSON)")

            XCTAssert(json.ip.isLikeIPAddress())
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
#if os(iOS)
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
#endif
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

        //test for failure on third entry
        XCTAssert(guardian.enter())
        XCTAssert(guardian.enter())
        XCTAssertFalse(guardian.enter())

        //counter should now be 1
        guardian.exit()

        //test custodian second entry for success
        let custodian:DispatchGuardCustodian = DispatchGuardCustodian(guardian)
        XCTAssert(custodian.acquired)

        //test custodian third entry for failure
        let custodian2:DispatchGuardCustodian = DispatchGuardCustodian(guardian)
        XCTAssertFalse(custodian2.acquired)

        //counter should now be 1
        guardian.exit()

        //remaining custodian will release last guard
    }

    func testExecuteOnce() {
        var highlander: UInt64 = 0

        DispatchQueue.executeOnce(identifier: "com.cyberdev.there_can_be_only_one") {
            highlander += 1
        }
        XCTAssert(highlander == 1)

        DispatchQueue.executeOnce(identifier: "com.cyberdev.there_can_be_only_one") {
            highlander += 1
        }
        XCTAssert(highlander == 1)
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
        XCTAssertFalse(String("foo*bar.com").isLikeEmailAddress())
        
        XCTAssert(String("1.1.1.1").isLikeIPV4Address())
        XCTAssertFalse(String("1.1..1").isLikeIPV4Address())
        XCTAssertFalse(String("1.1.1.512").isLikeIPV4Address())

        XCTAssert(String("2001:0000:3238:DFE1:63:0000:0000:FEFB").isLikeIPV6Address())
        XCTAssert(String("2001:0:3238:DFE1:63::FEFB").isLikeIPV6Address())
        XCTAssertFalse(String("FE80::F000::F000").isLikeIPV6Address())
        XCTAssertFalse(String("FE80:F000::BAR0").isLikeIPV6Address())

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
#if os(iOS)
        let green:String = "00FF00"
        let greenAlpha:String = "#00ff00ff"
        
        let greenColor:UIColor? = green.colorForHex()
        XCTAssertNotNil(greenColor)
        
        let greenAlphaColor:UIColor? = greenAlpha.colorForHex()
        XCTAssertNotNil(greenAlphaColor)
        
        let bad:String = "F00"
        let badColor:UIColor? = bad.colorForHex()
        XCTAssertNil(badColor)
        
        let color:UIColor? = UIColor(htmlHex: greenAlpha)
        XCTAssertNotNil(color)
        let colorComponents:[CGFloat]? = color?.cgColor.components
        XCTAssertNotNil(colorComponents)
        XCTAssert(colorComponents![0] == 0.0)
        XCTAssert(colorComponents![1] == 1.0)
        XCTAssert(colorComponents![2] == 0.0)
        XCTAssert(colorComponents![3] == 1.0)
#endif
    }

    func testCSV() {
        let tempFile = FileManager.default.temporaryFile

        let writeTest:[[String]] = [
            ["#", "A", "B", "C", "D"],
            ["1", "A,1", "B,1", "C,1", "D,1"],
            ["2", "A\"2\"", "B\"2\"", "C\"2\"", "D\"2\""],
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

    func testDateTime() {
        //extended precision 8601
        let dateString:String = "1965-11-13T13:07:36.639Z"
        guard let date8601:Date = DateFormatter.tryParseISO8601LikeDateString(dateString) else {
            XCTFail()
            return
        }
        XCTAssertEqual(date8601, Date(timeIntervalSince1970: -130391543.36100006))

        //Test overloaded TimeInterval initializers
        let milliTest = TimeInterval(milliseconds: 101.0);
        XCTAssertEqual(milliTest, 0.101);
        XCTAssertEqual(milliTest.microseconds.truncate(to: 1), 101000.0);

        let minuteTest = TimeInterval(days: 100.0);
        XCTAssertEqual(minuteTest, 8640000.0);
        XCTAssertEqual(minuteTest.hours, 2400.0);

        //create variable used below for relative/approximate time representations using
        // overloaded TimeInterval constructors
        let testDate: Date = Date();
        let tomorrow:Date = Date(timeInterval: TimeInterval(days: 1), since: testDate);
        let tomorrowInterval: TimeInterval = tomorrow.timeIntervalSince(testDate);
        XCTAssert(tomorrowInterval.hours == 24);

        //relative date string, test assumes system locale is english
        guard let relativity:String = DateFormatter.relativeDateTimeString(from: tomorrow,
                                                                     dateStyle: .medium,
                                                                     timeStyle: .none) else {
                                                                        XCTFail()
                                                                        return
        }
        XCTAssertEqual(relativity, "Tomorrow")

        //approximate duration string, test assumes system locale is english
        let approximate:String = tomorrow.timeIntervalSince(testDate).durationLocalizedDescription(approximation: true)
        XCTAssertEqual(approximate, "About 1 day")

        //duration string, test assumes system locale is english
        let localization:String = tomorrow.timeIntervalSince(testDate).durationLocalizedDescription()
        XCTAssertEqual(localization, "1 day")
    }
    
    //MARK: - Utility

    //Utility to tag failure messages in output
    func printFailure(_ description: String) {
        print("⚠️", description)
    }
}
