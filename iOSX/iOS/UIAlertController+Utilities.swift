//
//  UIAlertController+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 5/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController {
    
    /**
     Creates and returns a UIAlertController with optional OK and Cancel buttons. If handlers are not supplied for the OK or Cancel buttons then the associated actions will not be added to the alert.
     
     The titles for the OK and Cancel buttons are defined as NSLocalizedStrings for ease of localization.
     
     - parameters:
         - title: title of the alert
         - message: message of the alert
         - preferredStyle: style of the alert
         - okHandler: completion block for the OK action. If not supplied then no OK button will be added to the alert.
         - cancelHandler: completion block for the Cancel action. If not supplied then no OK button will be added to the alert.
     
     - returns: A UIAlertController
     
     */
    class func alertControllerOKCancel(title:String?, message:String?, preferredStyle:UIAlertControllerStyle, okHandler: ((UIAlertAction) -> Void)?, cancelHandler: ((UIAlertAction) -> Void)?) -> UIAlertController{
        
        let result = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        if let okHandler = okHandler {
            let okAction:UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "UIAlertController OK control"), style: .default, handler: okHandler)
            result.addAction(okAction)
        }
        
        if let cancelHandler = cancelHandler {
            let cancelAction:UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "UIAlertController Cancel control"), style: .cancel, handler: cancelHandler)
            result.addAction(cancelAction)
        }

        return result
    }
    
}
