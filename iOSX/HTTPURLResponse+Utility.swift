//
//  NSHTTPURLResponse+Utility.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/27/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public extension HTTPURLResponse {
    func isOK() -> Bool {
        return statusCode == 200
    }

    func isSuccess() -> Bool {
        return statusCode >= 200 && statusCode < 300
    }

    func notFound() -> Bool {
        return statusCode == 404
    }
}
