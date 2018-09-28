//
//  FormInputManager.swift
//  swiftlets
//
//  Created by Frank Vernon on 9/28/18.
//  Copyright © 2018 Frank Vernon. All rights reserved.
//

import Foundation

///Protocol for conformance to form element
/// Form elements are the objects (probably mostly UIContols)
///  used to collect information from the user.
///  See: FormInputTextField, FormInputSwitch
protocol FormInputElement {
    var isRequired: Bool {get set}
}

class FormInputTextField: UITextField, FormInputElement {
    var isRequired: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class FormInputSwitch: UISwitch, FormInputElement {
    var isRequired: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

///Protocol for conformance to form input manager
/// Manages form input elements and helps automate
/// next/done implementation for text input fields
/// TODO: utility for data collection and conversion to JSON
protocol FormInputManager {
    var formInputElements:Array<FormInputElement> {get set}
    var formComplete: Bool {get}

    func setReturnKeyType(for field: FormInputTextField)
    func nextTabbedTextField(after field: FormInputTextField?) -> FormInputTextField?
}

extension FormInputManager {
    private var activeFormInputControls:Array<FormInputElement> {
        return formInputElements.filter {
            switch $0 {
            case let control as UIControl:
                return control.isEnabled
                    && !control.isHidden
                    && control.alpha > 0

            default:
                return true;
            }
        }
    }

    var formComplete: Bool {
        return incompleteTabbedTextFields.isEmpty
    }

    //Text input field handling
    private var activeFormTextFields:[FormInputTextField] {
        return activeFormInputControls.compactMap { $0 as? FormInputTextField }
    }

    private var incompleteTabbedTextFields:[FormInputTextField] {
        return activeFormTextFields.filter {$0.isRequired && $0.text?.isEmpty != false}
    }

    func setReturnKeyType(for field: FormInputTextField) {
        field.returnKeyType = formComplete ? .done : .next
    }

    func nextTabbedTextField(after field: FormInputTextField?) -> FormInputTextField? {
        //get index of current field or return the first field in the set of incomplete fields
        guard let field = field, let current = incompleteTabbedTextFields.firstIndex(of: field) else {
            return incompleteTabbedTextFields.first
        }

        //get index of next field (if any) or return the first field in the set of active fields
        let next = incompleteTabbedTextFields.index(after: current)
        guard let result = incompleteTabbedTextFields.suffix(from: next).first else {
            return incompleteTabbedTextFields.first
        }

        return result;
    }
}
