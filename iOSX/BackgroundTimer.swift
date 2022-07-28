//
//  BackgroundTimer.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/27/22.
//  Copyright © 2022 Frank Vernon. All rights reserved.
//
// TODO: Create wrapper class with this and Timer to handle foreground/background cases transparently.

import Foundation

///Simple class to create/manage a non-repeating timer that runs while the app may be in the background. Your app must have
/// appropriate background mode support.
///
///The class is designed to be reused if desired. The timer duration can safely be changed after initialization and even after start is called.
///The closure is not called on stop().
open class BackgroundTimer {
    fileprivate var backgroundTask: UIBackgroundTaskIdentifier? = nil {
        willSet {
            if let backgroundTask = backgroundTask {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                timerStart = nil
            }
        }
    }
    
    ///closure will be called on the main thread. The boolean value indicates whether the timer expired (true) or
    ///if the background process was killed before reaching timer expiration (false). The closure will NOT be called in the
    ///event stop() is called.
    public var closure: (_ success: Bool) -> () = { _ in }

    private let timerQueue: DispatchQueue = DispatchQueue(label: "com.cyberdev.BackgroundTimer.queue")
    
    private var _duration: TimeInterval = .zero
    ///duration is TimeInterval for timer to fire after start() is called.
    public var duration: TimeInterval {
        get {
            timerQueue.sync {
                _duration
            }
        }
        set(value) {
            timerQueue.async() {
                self._duration = value
            }
        }
    }
    
    private var _timerStart: Date? = nil
    public var timerStart: Date? {
        get {
            timerQueue.sync {
                _timerStart
            }
        }
        set(value) {
            timerQueue.async() {
                self._timerStart = value
            }
        }
    }

    public var elapsed: TimeInterval {
        timerQueue.sync {
            guard let start = _timerStart else {
                return .zero
            }
            
            return abs(start.timeIntervalSinceNow)
        }
    }

    public var remaining: TimeInterval {
        timerQueue.sync {
            guard let start = _timerStart else {
                return .zero
            }
            
            return _duration - abs(start.timeIntervalSinceNow)
        }
    }
    
    ///tolerance is similar conceptually to that used by Timer class, see Timer class for details.
    public var tolerance: TimeInterval = 0.01
    
    ///Indicates if timer is currently running
    open var isRunning: Bool {
        backgroundTask != nil
    }

    public init(duration: TimeInterval = .zero,
                closure: @escaping ((Bool)->Swift.Void) = {_ in }) {
        self._duration = duration
        self.closure = closure
    }

    ///Start the timer running. Duration value on the object may be changed after start is called.
    ///
    ///Start will silently fail if the timer is already running. You can adjust duration to lengthen/shorten the timer run instead.
    open func start() {
        guard backgroundTask == nil else {
            return
        }
        
        //create background task
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "com.cyberdev.BackgroundTimer",
                                                                  expirationHandler: { [weak self] in
            //this called on main thread
            self?.backgroundTask = nil
            self?.closure(false)
        })
        
        let start = Date()
        timerStart = start
        
        DispatchQueue.global(qos: .background).async {
            //spinlock on thread until timer end within tolerance
            while self.remaining >= self.tolerance {
                Thread.sleep(forTimeInterval: self.tolerance)
            }
            
            //call completion on main thread
            DispatchQueue.main.async { [weak self] in
                //check that stop was not called while we were running
                guard self?.backgroundTask != nil else {
                    return
                }
                
                self?.backgroundTask = nil
                self?.closure(true)
            }
        }
    }
    
    ///Stop the timer. Closure will not be called.
    open func stop() {
        backgroundTask = nil
    }
}
