//
//  File.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/20/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

public extension UIViewController {
    class func topViewControllerForRoot(_ rootViewController:UIViewController?) -> UIViewController? {
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
    
    func move(to screen: UIScreen, retry: Int = 2, completion: @escaping (UIWindow?) -> Swift.Void) {
        guard let windowScene = UIApplication.shared.sceneForScreen(screen) else {
            if retry > 0 {
                DispatchQueue.main.asyncAfter(secondsFromNow: 1.0) {
                    self.move(to :screen, retry: retry - 1, completion: completion)
                }
            } else {
                completion(nil)
            }
            return
        }

        let displayWindow = { () -> UIWindow in
            let window = UIWindow(frame: screen.bounds)
            window.rootViewController = self
            window.windowScene = windowScene
            window.isHidden = false
            window.makeKeyAndVisible()
            return window
        }()
        
        completion(displayWindow)
    }
    
    class func loadVC(vcName: String, fromStoryboard sbName: String) -> UIViewController {
        let storyboard = UIStoryboard(name: sbName, bundle: nil)
        return storyboard.instantiateViewController(identifier: vcName)
    }
}
