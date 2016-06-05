//
//  Timer.swift
//  Segues
//
//  Created by Frank Vernon on 9/15/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import Foundation

/// An NSTimer wrapper with closure semantics. Wrapper ensures all operations occur on main thread.
public class Timer {
    private var completion: (timer: Timer) -> () = { (timer: Timer) in }
    private var timer:NSTimer?
    private var duration:NSTimeInterval?
    private var tolerance:Float?
    private var repeats:Bool = false
    
    private var _running:Bool = false
    public var running:Bool {
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
    public func start(duration: NSTimeInterval, repeats: Bool = false, tolerance:Float = 0.1, handler:(timer: Timer)->()) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self._stop()
            self.completion = handler
            self.repeats = repeats
            self.timer = NSTimer.scheduledTimerWithTimeInterval(duration,
                target: self,
                selector: #selector(Timer.processHandler(_:)),
                userInfo: nil,
                repeats: repeats)
            self.timer!.tolerance = duration * NSTimeInterval(tolerance)
            self._running = true
        })
    }
    
    /**
     Restart a running or stopped timer. Noop if timer has not previously been started.
     */
    public func restart() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
    public func stop() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self._stop()
        })
    }
    
    private func _stop() {
        self._running = false
        if let timer = self.timer {
            timer.invalidate()
        }
    }
    
    @objc private func processHandler(timer: NSTimer) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if !self.repeats {
                self._stop()
            }
            self.completion(timer: self)
        })
    }
    
    public func fire() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let timer = self.timer {
                timer.fire()
            }
        })
    }
}
