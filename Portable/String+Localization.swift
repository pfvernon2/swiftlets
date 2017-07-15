//
//  String+Localization.swift
//  swiftlets
//
//  Created by Frank Vernon on 6/6/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import Foundation

extension String {
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
