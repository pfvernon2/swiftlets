//
//  Platform.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/21/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

public struct Platform {
    static var isSimulator: Bool {
        TARGET_OS_SIMULATOR != 0
    }

    static var isIPhone: Bool {
        TARGET_OS_IPHONE != 0
    }

    static var isIOS: Bool {
        TARGET_OS_IOS != 0
    }

    static var isWatch: Bool {
        TARGET_OS_WATCH != 0
    }

    static var isTV: Bool {
        TARGET_OS_TV != 0
    }

    static var isMac: Bool {
        TARGET_OS_MAC != 0
    }

    static var isUnix: Bool {
        TARGET_OS_UNIX != 0
    }

    static var isCrap: Bool {
        TARGET_OS_WIN32 != 0
    }
}
