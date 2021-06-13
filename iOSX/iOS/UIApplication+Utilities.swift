//
//  UIApplication+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/11/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIApplication {
    public class var windowInterfaceOrientation: UIInterfaceOrientation? {
        return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
    }

    public class func jumpOutToAppPreferences() {
        guard let settingsURL:URL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL) else {
                return
        }
        
        UIApplication.shared.open(settingsURL)
    }
    
    public class func appInBackground() -> Bool {
        switch UIApplication.shared.applicationState {
        case .background, .inactive:
            return true
        default:
            return false
        }
    }
    
    public class func appVersion() -> String? {
        guard let dictionary = Bundle.main.infoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String else {
                return nil
        }
        
        return version
    }
    
    public class func appDescription() -> String? {
        guard let dictionary = Bundle.main.infoDictionary,
            let name = dictionary["CFBundleExecutable"] as? String,
            let version = dictionary["CFBundleShortVersionString"] as? String,
            let build = dictionary["CFBundleVersion"] as? String else {
                return nil
        }
        
        return "\(name) \(version) (\(build))"
    }
    
    ///Returns Window Scene for associated Screen
    public func sceneForScreen(_ screen: UIScreen) -> UIWindowScene? {
        connectedScenes.first(where: { (scene) -> Bool in
            guard let windowScene = scene as? UIWindowScene else {
                return false
            }
            
            return windowScene.screen == screen
        }) as? UIWindowScene
    }
}
