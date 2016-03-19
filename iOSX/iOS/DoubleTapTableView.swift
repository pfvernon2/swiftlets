//
//  DoubleTapTableView.swift
//  Segues
//
//  Created by Frank Vernon on 12/2/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import UIKit

protocol DoubleTapTableViewDelegate: UITableViewDelegate {
    func tableView(tableView: UITableView, didDoubleTapRowAtIndexPath indexPath: NSIndexPath)
}

class DoubleTapTableView: UITableView {
    
    var doubleTapDelegate: DoubleTapTableViewDelegate? {
        get {
            return self.delegate as? DoubleTapTableViewDelegate
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch:UITouch in touches {
            if touch.tapCount == 2 {
                if let row:NSIndexPath = indexPathForRowAtPoint(touch.locationInView(self)) {
                    doubleTapDelegate?.tableView(self, didDoubleTapRowAtIndexPath: row)
                }
            }
        }

        super.touchesEnded(touches, withEvent: event)
    }
    
}
