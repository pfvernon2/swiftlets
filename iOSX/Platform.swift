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
        return TARGET_OS_SIMULATOR != 0
    }

    static var isIPhone: Bool {
        return TARGET_OS_IPHONE != 0
    }

    static var isIOS: Bool {
        return TARGET_OS_IOS != 0
    }

    static var isWatch: Bool {
        return TARGET_OS_WATCH != 0
    }

    static var isTV: Bool {
        return TARGET_OS_TV != 0
    }

    static var isMac: Bool {
        return TARGET_OS_MAC != 0
    }

    static var isUnix: Bool {
        return TARGET_OS_UNIX != 0
    }

    static var isCrap: Bool {
        return TARGET_OS_WIN32 != 0
    }
}
