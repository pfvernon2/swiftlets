//
//  ConsoleView.swift
//  swiftlets
//
//  Created by Frank Vernon on 3/12/22.
//  Copyright © 2022 Frank Vernon. All rights reserved.
//

import UIKit

///Super sketchy console like view for on-device debugging.
/// Note that all instances of ConsoleView in the app are updated when print() is called.
/// This is likely useful only for debugging purposes on-device where
/// normal console output is not readily available.
///
/// - note: This is not recommended or intended for production use. You have been warned.
public class ConsoleView: UITextView  {
    private static var instances: [WeakContainer<ConsoleView>] = []
    public static func print(_ args: String...) {
        let line = args.joined(separator: " ")
        instances.forEach { $0.get()?.appendLine(line) }
    }

    var atBottom = true
    
    public override func awakeFromNib() {
        makeConsole()
    }
        
    func makeConsole() {
        backgroundColor = .black
        textColor = .white
        font = UIFont.monospacedSystemFont(ofSize: 16.0, weight: .regular)
        isEditable = false
        
        //populate new instance with content of existing views
        text = ConsoleView.instances.first?.get()?.text
        scrollToEnd()

        //to get user scroll notifications
        super.delegate = self
                
        ConsoleView.instances.append(WeakContainer(value:self))
    }
}

extension ConsoleView: UITextViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        atBottom = scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height
    }
}

extension ConsoleView {
    func appendLine(_ line : String, scroll: Bool? = nil) {
        if text.isNotEmpty && text.last != "\n" {
            text.append("\n")
        }
        text.append(line)
        
        //if scroll override is supplied use it exclusively
        if let scroll = scroll {
            if scroll {
                scrollToEnd()
            }
        }
        //otherwise scroll if previously at bottom
        else if atBottom {
            scrollToEnd()
        }
    }
    
    func scrollToEnd() {
        if text.count > 0 {
            let location = text.count - 1
            let bottom = NSMakeRange(location, 1)
            scrollRangeToVisible(bottom)
        }
        atBottom = true
    }
}
