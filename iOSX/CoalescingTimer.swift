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
 var delayedOperationTimer:CoalescingTimer? = nil

 override func awakeFromNib() {
     //Create a timer to save current state 1 second after the user completes
     // their touch operation.
     delayedOperationTimer = CoalescingTimer(duration:1.0) { (CoalescingTimer) in
         //Save state
     }
}
 
 override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
     //User ends operation so restart the timer.
     delayedOperationTimer?.prime()
 }

 override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
    //User begins new operation so restart the timer.
    delayedOperationTimer?.restart()
 }
 
 override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
    //User still moving so restart the timer.
    delayedOperationTimer?.restart()
 }

 ````
*/
open class CoalescingTimer {
    fileprivate var timer:Timer?
    fileprivate var duration:TimeInterval {
        didSet {
            if running {
                restart()
            }
        }
    }
    fileprivate var repeats:Bool = false
    fileprivate var tolerance:Float = 0.1
    fileprivate var closure: (_ timer:CoalescingTimer) -> () = { (CoalescingTimer) in }
    fileprivate weak var queue:DispatchQueue? = DispatchQueue.main
    
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
     Create a timer with closure.
     
     - Parameter duration: The duration in seconds between start and when the closure is invoked.
     - Parameter repeats: Indicate if timer should repeat. Defaults to false
     - Parameter tolerance: The percentage of time after the scheduled fire date that the timer may fire. Defaults to 0.1. Range 0.0...1.0. Using a non-zero tolerance value when timing accuracy is not crucial allows the OS to better optimize for power and CPU usage.
     - Parameter queue: The DispatchQueue to invoke the closure on.
     - Parameter closure: The closure to be invoked when the timer fires.
    */
    public init(duration: TimeInterval, repeats: Bool = false, tolerance:Float = 0.1, queue:DispatchQueue = DispatchQueue.main, closure: @escaping (CoalescingTimer)->()) {
        self.closure = closure
        self.duration = duration
        self.repeats = repeats
        self.queue = queue
    }
    
    /**
     Start the timer if not running.
    */
    open func prime() {
        DispatchQueue.main.async { () -> Void in
            if self.timer == nil {
                self.start()
            }
            else if let timer = self.timer, !timer.isValid {
                self.start()
            }
        }
    }
    
    /**
     Start the timer. Currently running timers are stoped without firing.
    */
    open func start() {
        DispatchQueue.main.async { () -> Void in
            self._stop()

            self.timer = Timer.scheduledTimer(withTimeInterval: self.duration, repeats: self.repeats) { (timer) in
                self.queue?.async {
                    self.closure(self)
                }
            }
            
            self.timer?.tolerance = self.duration * TimeInterval(self.tolerance)
        }
    }
    
    /**
     Restart a previously running timer or no-op if not running
     */
    open func restart() {
        DispatchQueue.main.async { () -> Void in
            guard let timer = self.timer else {
                return
            }
                        
            if timer.isValid {
                timer.fireDate = Date(timeIntervalSinceNow: self.duration)
            } else {
                self.start()
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
     If the timer is non-repeating it is invalidated after fiing.
     */
    open func fire() {
        DispatchQueue.main.async {() -> Void in
            guard let timer = self.timer, timer.isValid else {
                return
            }
            timer.fire()
        }
    }

    //MARK: - Internal Implementation
    fileprivate func _stop() {
        guard let timer = self.timer else {
            return
        }
        timer.invalidate()
        self.timer = nil
    }
}
