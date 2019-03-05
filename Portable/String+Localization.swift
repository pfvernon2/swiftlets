//
//  String+Localization.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension String {
    /**
     Utility initer for referencing localizable strings.

     - note: This mechanism undermines Xcodes ability to generate lists of localized strings in your application
     and thus has limited value in production applications. While it would be possible to create your own scripts
     to replicate this functionality I have not done so.
     */
    public init?(localized:String, comment:String? = nil) {
        self.init(NSLocalizedString(localized, comment: comment ?? ""))
    }
    
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
    
    func localized(withComment comment:String, bundle:Bundle = Bundle.main, tableName:String? = nil) -> String {
        return NSLocalizedString(self, tableName: tableName, bundle: Bundle.main, value: "", comment: comment)
    }
}
