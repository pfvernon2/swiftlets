//
//  UIApplication+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIApplication {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    class func jumpOutToAppPreferences() {
        guard let settingsURL:NSURL = NSURL(string: UIApplicationOpenSettingsURLString)
            where UIApplication.sharedApplication().canOpenURL(settingsURL) else {
                return
        }
        
        UIApplication.sharedApplication().openURL(settingsURL)
    }
}