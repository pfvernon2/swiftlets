//
//  CoalescingTimer.swift
//  swiftlets
//
//  Created by Frank Vernon on 9/15/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import Foundation

/**
A Timer wrapper with simple coalescing and reuse semantics.
 
This timer class is particularly useful when using a delayed operation pattern where an operation is
to be performed in a batched or coalesced fashion, for example when the device becomes idle.
 
 - Note: The wrapper ensures all operations occur on main queue.
 
````
 var delayedOperationTimer:CoalescingTimer = CoalescingTimer()
 
 override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
    delayedOperationTimer.start(duration:5.0) { (CoalescingTimer) in
        //Save state
    }
 }
 
 override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
    delayedOperationTimer.restart()
 }
 
 override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    delayedOperationTimer.stop()
 }

 ````
*/
open class CoalescingTimer {
    fileprivate var closure: (_ timer:CoalescingTimer) -> () = { (CoalescingTimer) in }
    fileprivate var timer:Timer?
    fileprivate var repeats:Bool = false
    fileprivate var tolerance:Float = 0.1
    fileprivate var duration:TimeInterval? {
        didSet {
            if running {
                restart()
            }
        }
    }
    
    open var running:Bool {
        get {
            guard let timer = timer else {
                return false
            }
            
            return timer.isValid
        }
    }
    
    deinit {
        self._stop()
    }
    
    /**
     Start a timer with closure. Currently running timers are stoped without firing.
     
     - Parameter duration: The duration in seconds between start and when the closure is invoked.
     - Parameter repeats: Indicate if timer should repeat. Defaults to false
     - Parameter tolerance: The percentage of time after the scheduled fire date that the timer may fire. Defaults to 0.1. Range 0.0...1.0. Using a non-zero tolerance value when timing accuracy is not crucial allows the OS to better optimize for power and CPU usage.
     - Parameter handler: The closure to be invoked when the timer fires.
    */
    open func start(duration: TimeInterval, repeats: Bool = false, tolerance:Float = 0.1, queue:DispatchQueue = DispatchQueue.main, closure: @escaping (CoalescingTimer)->()) {
        DispatchQueue.main.async { () -> Void in
            self._stop()
            self.closure = closure
            self.duration = duration
            self.repeats = repeats
            
            self.timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: repeats) { (timer) in
                queue.async {
                    self.closure(self)
                }
            }
            
            self.timer?.tolerance = duration * TimeInterval(tolerance)
        }
    }
    
    /**
     Restart a previously running timer. Noop if timer was not previously started.
     */
    open func restart() {
        DispatchQueue.main.async { () -> Void in
            guard let timer = self.timer else {
                return
            }
            
            guard let duration = self.duration else {
                return
            }
            
            if timer.isValid {
                timer.fireDate = Date(timeIntervalSinceNow: duration)
            } else {
                self.start(duration: duration, repeats: self.repeats, tolerance: self.tolerance, closure: self.closure)
            }
        }
    }
    
    /**
     Stop the timer without firing.
     */
    open func stop() {
        DispatchQueue.main.async { () -> Void in
            self._stop()
        }
    }
    
    /**
     Forces timer to fire immediately without interrupting regular fire scheduling.
     If the timer is non-repeating it is automatically invalidated after fiing.
     */
    open func fire() {
        DispatchQueue.main.async {() -> Void in
            if let timer = self.timer, timer.isValid {
                timer.fire()
            }
        }
    }

    //MARK: - Internal Implementation
    fileprivate func _stop() {
        guard let timer = self.timer else {
            return
        }
        timer.invalidate()
    }
}
