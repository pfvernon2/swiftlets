//
//  String+Localization.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension String {
    public init(localized:String, comment:String?) {
        self.init(NSLocalizedString(localized, comment: comment ?? ""))
    }
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
    
    func localizedWithComment(comment:String, bundle:NSBundle = NSBundle.mainBundle(), tableName:String? = nil) -> String {
        return NSLocalizedString(self, tableName: tableName, bundle: NSBundle.mainBundle(), value: "", comment: comment)
    }
}