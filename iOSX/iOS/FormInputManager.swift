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
    var isComplete: Bool {get}
}

///Example of UITextField implementing FormInputElement protocol
class FormInputTextField: UITextField, FormInputElement {
    // FormInputElement
    var isRequired: Bool = true
    var isComplete: Bool {
        //You may want to create your own subclass or
        // to perform appropriate validation of the
        // contents of the text field.
        (text?.isEmpty) ?? false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

///Example of UISwitch implementing FormInputElement protocol
class FormInputSwitch: UISwitch, FormInputElement {
    // FormInputElement
    var isRequired: Bool = false
    var isComplete: Bool {
        true
    }

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
/// This would most likely be used on a UIViewController to
/// implement tabbing between fields and basic form validation.
protocol FormInputManager {
    ///The list of controls associated with your input form
    /// - Note: The order of this array defines the order of tabbing operations.
    var formInputElements:Array<FormInputElement> {get set}

    ///Indicates all input elements indicated as 'required' have
    /// been completed.
    var formComplete: Bool {get}

    ///Text field next/done return key utility.
    ///
    /// When using default implementation you can call this with 'nil'
    /// to get first incomplete input field.
    func nextTabbedTextField(after field: FormInputTextField?) -> FormInputTextField?
}

extension FormInputManager {
    var formComplete: Bool {
        formInputElements.contains{$0.isRequired && !$0.isComplete}
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

    //Utility method to get array of active UIControls
    // Active controls are defined as those which are enabled and visible
    private var activeFormControls:Array<FormInputElement> {
        return formInputElements.filter {
            guard let control:UIControl = $0 as? UIControl else {
                return false
            }
            return control.isEnabled && !control.isHidden && control.alpha > 0
        }
    }

    //Text input field handling
    private var activeFormInputTextFields:[FormInputTextField] {
        activeFormControls.compactMap {$0 as? FormInputTextField}
    }

    private var incompleteFormInputTextFields:[FormInputTextField] {
        activeFormInputTextFields.filter {$0.isRequired && !$0.isComplete}
    }

    func setReturnKeyType(for field: FormInputTextField) {
        field.returnKeyType = formComplete ? .done : .next
    }
}
