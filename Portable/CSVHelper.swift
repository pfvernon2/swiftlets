//
//  CSVHelper.swift
//  swiftlets
//
//  Created by Frank Vernon on 10/28/14.
//  Copyright (c) 2014 Frank Vernon. All rights reserved.
//

import UIKit

fileprivate let fieldDelimiter:Character = ","
fileprivate let recordDelimiter:Character = "\r\n"
fileprivate let bareReturn:Character = "\r"
fileprivate let bareLinefeed:Character = "\n"
fileprivate let quoteCharacter:Character = "\""
fileprivate let escapeSequence:String = "\"\""
fileprivate let quoteSequence:String = String("\"")
fileprivate let fieldDelimiterSequence:String = String(",")

///RFC 4180 compliant CSV parser/writer
class CSVHelper: NSObject {
	
	func read(contentsOfURL url: URL, useEncoding encoding: String.Encoding = String.Encoding.utf8) -> [[String]] {
		let characterData:String = try! String(contentsOfFile: url.path, encoding: encoding)
		var table:[[String]] = []
		
		var quoted:Bool = false
		var testEscaped:Bool = false
		var testRecordEnd:Bool = false
		var field:String = ""
		var record:[String] = []
        for current:Character in characterData.characters {
			if testEscaped && current != quoteCharacter {
				testEscaped = false
				quoted = false
			}
			
			//check for escape sequence start
			if current == quoteCharacter && quoted && !testEscaped {
				testEscaped = true
				continue
			}
				
            //check for quote sequence start
			else if current == quoteCharacter && !testEscaped {
				quoted = !quoted
			}
				
            //if not quoted check for record delimiter(s)
            // supporting bare CR & LF, not required by RFC4180 but common
			else if !quoted && (current == bareReturn || current == bareLinefeed) {
				testRecordEnd = true
                continue
			}
                
            //if outside of quoted section and at end of record then: add last field to record,
            // add record to table, prepare to parse next record
			else if !quoted && (current == recordDelimiter || testRecordEnd) {
				record.append(field)
				table.append(record)
				record = []
				field = ""
				if testRecordEnd {
					field.append(current)
				}
			}
				
            //if not quoted check for field delimiter
			else if !quoted && current == fieldDelimiter {
				record.append(field)
				field = ""
			}
				
            //add character to current field
			else {
				field.append(current)
			}
			
			testEscaped = false
			testRecordEnd = false
		}
		
		return table
	}
    
	func write(_ table: [[String]], toFile url: URL, useEncoding encoding: String.Encoding = String.Encoding.utf8) {
        guard let stream = OutputStream(url: url, append: true) else {
            return
        }
        stream.open()
        
        defer {
            stream.close()
        }
        
        table.forEach { (record) in
            stream.write(encode(record: record))
        }
	}
    
    fileprivate func encode(record: [String]) -> String {
        let escapedRecord:[String] = record.map { (field) -> String in
            guard field.contains(quoteCharacter) else {
                return field
            }
            
            let escapedField = field.replacingOccurrences(of: quoteSequence, with: escapeSequence, options: NSString.CompareOptions.literal, range: nil)
            return quoteSequence + escapedField + quoteSequence
        }
        return escapedRecord.joined(separator: fieldDelimiterSequence)
    }
}

fileprivate extension OutputStream {
    
    /// Write `String` to `OutputStream`
    ///
    /// - parameter string:                The `String` to write.
    /// - parameter encoding:              The `String.Encoding` to use when writing the string. This will default to `.utf8`.
    /// - parameter allowLossyConversion:  Whether to permit lossy conversion when writing the string. Defaults to `false`.
    ///
    /// - returns:                         Return total number of bytes written upon success. Return `-1` upon failure.
    
    @discardableResult func write(_ string: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) -> Int {
        
        if let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) {
            return data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int in
                var pointer = bytes
                var bytesRemaining = data.count
                var totalBytesWritten = 0
                
                while bytesRemaining > 0 {
                    let bytesWritten = self.write(pointer, maxLength: bytesRemaining)
                    if bytesWritten < 0 {
                        return -1
                    }
                    
                    bytesRemaining -= bytesWritten
                    pointer += bytesWritten
                    totalBytesWritten += bytesWritten
                }
                
                return totalBytesWritten
            }
        }
        
        return -1
    }
    
}
