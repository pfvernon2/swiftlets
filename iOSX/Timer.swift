//
//  Timer.swift
//  Segues
//
//  Created by Frank Vernon on 9/15/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import Foundation

/// An NSTimer wrapper with closure semantics. Wrapper ensures all operations occur on main thread.
open class Timer {
    fileprivate var completion: (_ timer: Timer) -> () = { (timer: Timer) in }
    fileprivate var timer:Foundation.Timer?
    fileprivate var duration:TimeInterval? {
        didSet {
            if running {
                restart()
            }
        }
    }
    fileprivate var tolerance:Float?
    fileprivate var repeats:Bool = false
    
    fileprivate var _running:Bool = false
    open var running:Bool {
        get {
            return _running
        }
    }
    
    deinit {
        stop()
    }
    
    /**
     Start a timer with a completion closure.
     
     - Parameter duration: The duration in seconds between start and when the completion block is invoked.
     - Parameter repeats: Indicate if timer should repeat. Defaults to false
     - Parameter tolerance: The percentage of time after the scheduled fire date that the timer may fire. Defaults to 0.0. Range 0.0...1.0. Using a tolerance when timing accuracy is not crucial allows the OS to better optimize for power and CPU usage.
     - Parameter handler: The completion block to be invoked when the timer fires.

     */
    open func start(_ duration: TimeInterval, repeats: Bool = false, tolerance:Float = 0.1, handler:@escaping (_ timer: Timer)->()) {
        DispatchQueue.main.async(execute: { () -> Void in
            self._stop()
            self.completion = handler
            self.repeats = repeats
            self.timer = Foundation.Timer.scheduledTimer(timeInterval: duration,
                target: self,
                selector: #selector(Timer.processHandler(_:)),
                userInfo: nil,
                repeats: repeats)
            self.timer!.tolerance = duration * TimeInterval(tolerance)
            self._running = true
        })
    }
    
    /**
     Restart a running or stopped timer. Noop if timer has not previously been started.
     */
    open func restart() {
        DispatchQueue.main.async(execute: { () -> Void in
            guard let duration = self.duration else {
                return
            }
            
            guard let tolerance = self.tolerance else {
                return
            }
            
            self.start(duration, repeats: self.repeats, tolerance: tolerance, handler: self.completion)
        })
    }
    
    /**
     Stop the timer.
     */
    open func stop() {
        DispatchQueue.main.async(execute: { () -> Void in
            self._stop()
        })
    }
    
    fileprivate func _stop() {
        self._running = false
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    @objc fileprivate func processHandler(_ timer: Foundation.Timer) {
        DispatchQueue.main.async(execute: { () -> Void in
            if !self.repeats {
                self._stop()
            }
            self.completion(self)
        })
    }
    
    open func fire() {
        DispatchQueue.main.async(execute: { () -> Void in
            if let timer = self.timer {
                timer.fire()
            }
        })
    }
}
