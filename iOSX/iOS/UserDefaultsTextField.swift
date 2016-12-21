//
//  UserDefaultsTextField.swift
//  swiftlets
//
//  Created by Frank Vernon on 12/21/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import UIKit

/**
 UITextField subclass for reading and writting values to/from UserDefaults with an optional input validation closure. 
 */
open class UserDefaultsTextField: UITextField {
    ///Key for retrieving value from, and setting value on, UserDefaults.standard
    internal var userDefaultsKey:String? {
        didSet (oldKey) {
            if let oldKey = oldKey {
                UserDefaults.standard.removeObserver(self, forKeyPath: oldKey)
            }

            guard let newKey = userDefaultsKey else {
                self.text = String()
                return
            }
            
            UserDefaults.standard.addObserver(self, forKeyPath: newKey, options: [.new], context: nil)
            if let value:String = UserDefaults.standard.string(forKey: newKey) {
                self.text = value
            }
        }
    }
    
    /**
     Closure for validating the input to the text field before it is written to user defaults.
     
     - Parameter value: The proposed new value of the text field
     
     - Returns: Implementation should return a boolean indicating if the supplied value, 
     or the optional substituion value, should be written to UserDefaults.standard. The substitution value,
     if supplied, will both be written to UserDefaults.standard and displayed in the field upon return.
     */
    public typealias stringValidation = (_ value:String?) -> (Bool,String?)
    
    ///An optional closure for validating the field changes before they are written to user defaults
    public var stringValidationClosure:stringValidation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.delegate = self
    }
    
    deinit {
        if let key = self.userDefaultsKey {
            UserDefaults.standard.removeObserver(self, forKeyPath: key)
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {
        guard let newValue:String = change?[NSKeyValueChangeKey.newKey] as? String else {
            return
        }
        
        self.text = newValue
    }
}

extension UserDefaultsTextField: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateUserDefaults()
        return false
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateUserDefaults()
    }
    
    fileprivate func updateUserDefaults() {
        guard let key = self.userDefaultsKey else {
            return
        }
        
        var newValue = self.text
        if let validator = self.stringValidationClosure {
            let (result, substitution) = validator(newValue)
            if !result {
                return
            }
            
            if substitution != nil {
                newValue = substitution
            }
        }
        
        UserDefaults.standard.set(newValue, forKey: key)
    }
}
