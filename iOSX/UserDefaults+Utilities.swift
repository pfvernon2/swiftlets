//
//  UserDefaults+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 2/27/21.
//  Copyright © 2021 Frank Vernon. All rights reserved.
//

import Foundation

public protocol UserDefaultKeyValue {
    associatedtype ValueType
    
    var key: String {get}
    var defaultValue: ValueType {get}
    
    func get() -> ValueType
    func set(_ _value:ValueType)
    func remove()
}

public extension UserDefaultKeyValue {
    func get() -> ValueType {
        UserDefaults.standard.value(forKey: key) as? ValueType ?? defaultValue
    }
    
    func set(_ _value:ValueType) {
        UserDefaults.standard.setValue(_value, forKey: key)
    }
    
    func remove() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

public extension UserDefaults {
    ///setObject(forKey:) where value != nil, removeObjectForKey where value == nil
    func setOrRemoveObject(_ value: Any?, forKey defaultName: String) {
        guard (value != nil) else {
            UserDefaults.standard.removeObject(forKey: defaultName)
            return
        }

        UserDefaults.standard.set(value, forKey: defaultName)
    }
}
