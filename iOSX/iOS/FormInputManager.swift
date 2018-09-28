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

///Example of UITextField implementing FormInputElement protocol
/// If you have your own UITextField subclasses you need only implement 'isRequired'.
class FormInputTextField: UITextField, FormInputElement {
    var isRequired: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

///Example of UISwitch implementing FormInputElement protocol
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
    //list of elements associated with your input form
    var formInputElements:Array<FormInputElement> {get set}

    //indicates all input elements indicated as 'required' have
    // been completed. You may want/need to override the default
    // implementation in cases where you have input fields other than
    // text fields that require validation.
    var formComplete: Bool {get}

    //Text field next/done return key utility
    // When using default implementation you can call this with 'nil'
    //  to get first available input field.
    func nextTabbedTextField(after field: FormInputTextField?) -> FormInputTextField?

    var formJSON: JSON {get}
}

extension FormInputManager {
    private var activeFormInputElements:Array<FormInputElement> {
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
        return incompleteFormInputTextFields.isEmpty
    }

    //Text input field handling
    private var activeFormInputTextFields:[FormInputTextField] {
        return activeFormInputElements.compactMap { $0 as? FormInputTextField }
    }

    private var incompleteFormInputTextFields:[FormInputTextField] {
        return activeFormInputTextFields.filter {$0.isRequired && $0.text?.isEmpty != false}
    }

    func setReturnKeyType(for field: FormInputTextField) {
        field.returnKeyType = formComplete ? .done : .next
    }

    func nextTabbedTextField(after field: FormInputTextField? = nil) -> FormInputTextField? {
        //get index of current field or return the first field in the set of incomplete fields
        guard let field = field, let current = incompleteFormInputTextFields.firstIndex(of: field) else {
            return incompleteFormInputTextFields.first
        }

        //get index of next field (if any) or return the first field in the set of active fields
        let next = incompleteFormInputTextFields.index(after: current)
        guard let result = incompleteFormInputTextFields.suffix(from: next).first else {
            return incompleteFormInputTextFields.first
        }

        //set return key type of next field as appropriate
        setReturnKeyType(for: result);
        return result;
    }
}
