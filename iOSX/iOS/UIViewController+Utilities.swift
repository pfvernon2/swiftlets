//
//  File.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/20/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

extension UIViewController {
    class func topMostViewController() -> UIViewController? {
        return UIViewController.topViewControllerForRoot(UIApplication.sharedApplication().keyWindow?.rootViewController)
    }
    
    class func topViewControllerForRoot(rootViewController:UIViewController?) -> UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        
        guard let presented = rootViewController.presentedViewController else {
            return rootViewController
        }
        
        switch presented {
        case is UINavigationController:
            let navigationController:UINavigationController = presented as! UINavigationController
            return UIViewController.topViewControllerForRoot(navigationController.viewControllers.last)
            
        case is UITabBarController:
            let tabBarController:UITabBarController = presented as! UITabBarController
            return UIViewController.topViewControllerForRoot(tabBarController.selectedViewController)

        default:
            return UIViewController.topViewControllerForRoot(presented)
        }
    }
}
