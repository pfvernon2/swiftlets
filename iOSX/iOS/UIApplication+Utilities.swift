//
//  UIApplication+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIApplication {
    class func jumpOutToAppPreferences() {
        guard let settingsURL:URL = URL(string: UIApplicationOpenSettingsURLString)
            , UIApplication.shared.canOpenURL(settingsURL) else {
                return
        }
        
        UIApplication.shared.openURL(settingsURL)
    }

    class func appInBackground() -> Bool {
        switch UIApplication.shared.applicationState {
        case .background, .inactive:
            return true
        default:
            return false
        }
    }

    public class func appVersion() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }

        guard let version = dictionary["CFBundleShortVersionString"] as? String else {
            return ""
        }

        return version
    }

    public class func appDescription() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }

        guard let name = dictionary["CFBundleExecutable"] as? String,
            let version = dictionary["CFBundleShortVersionString"] as? String,
            let build = dictionary["CFBundleVersion"] as? String else {
                return ""
        }

        return "\(name) \(version) (\(build))"
    }
}

