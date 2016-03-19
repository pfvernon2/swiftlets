//
//  Timer.swift
//  Segues
//
//  Created by Frank Vernon on 9/15/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import Foundation

/// An NSTimer wrapper with block completion semantics. Wrapper ensures all operations occur on main thread.
public class Timer {
    private var completion: (timer: Timer) -> () = { (timer: Timer) in }
    private var timer:NSTimer?
    private var repeats:Bool?
    
    deinit {
        stop()
    }
    
    /**
     Start a timer with a completion block.
     
     - Parameter duration: The duration in seconds between start and when the completion block is invoked.
     - Parameter repeats: Indicate if timer should repeat. Defaults to false
     - Parameter tolerancePercent: The percentage of time after the scheduled fire date that the timer may fire. Defaults to 0.0. Range 0.0::1.0. Using a tolerance when timing accuracy is not crucial allows the OS to better optimize for power and CPU usage.
     - Parameter handler: The completion block to be invoked when the timer fires.

     */
    public func start(duration: NSTimeInterval, repeats: Bool = false, tolerancePercent:Float = 0.0, handler:(timer: Timer)->()) {
        gcd.main().async { () -> () in
            self._stop()
            self.completion = handler
            self.repeats = repeats
            self.timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "processHandler:", userInfo: nil, repeats: repeats)
            self.timer!.tolerance = duration * NSTimeInterval(tolerancePercent)
        }
    }
    
    /**
     Stop the timer.
     */
    public func stop() {
        gcd.main().async { () -> () in
            self._stop()
        }
    }
    
    private func _stop() {
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    @objc private func processHandler(timer: NSTimer) {
        gcd.main().async { () -> () in
            if !self.repeats! {
                self.timer!.invalidate()
            }
            self.completion(timer: self)
        }
    }
}
