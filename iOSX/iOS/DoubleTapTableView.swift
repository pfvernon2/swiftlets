//
//  DoubleTapTableView.swift
//  swiftlets
//
//  Created by Frank Vernon on 12/2/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import UIKit

/**
 Protocol associated with DoubleTapTableView for detecting double and single taps on table rows.

 This protocol extends UITableViewDelegate so you can easily use this in place of your standard delegate handling.
 */
protocol DoubleTapTableViewDelegate: UITableViewDelegate {
    func tableView(tableView: UITableView, didTapRowAtIndexPath indexPath: IndexPath)
    func tableView(tableView: UITableView, didDoubleTapRowAtIndexPath indexPath: IndexPath)
}

/**
 UITableView subclass and delegate that automatically detects double tap gestures on table view rows
 */
class DoubleTapTableView: UITableView {
    var doubleTapDelegate: DoubleTapTableViewDelegate? {
        get {
            self.delegate as? DoubleTapTableViewDelegate
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { (touch) in
            if let row:IndexPath = indexPathForRow(at: touch.location(in: self)) {
                switch touch.tapCount {
                case 1:
                    doubleTapDelegate?.tableView(tableView: self, didTapRowAtIndexPath: row)
                case 2:
                    doubleTapDelegate?.tableView(tableView: self, didDoubleTapRowAtIndexPath: row)
                default:
                    break
                }
            }
        }

        super.touchesEnded(touches, with: event)
    }
}
