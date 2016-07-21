//
//  Reachability.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/21/16.
//  Copyright © 2016 Frank Vernon. All rights reserved.
//

import SystemConfiguration
import Foundation

private struct NetworkReachabilityPlatform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

public extension SCNetworkReachabilityFlags {
    public func isOnWWAN() -> Bool {
        #if os(iOS)
            return self.contains(.IsWWAN)
        #else
            return false
        #endif
    }

    public func isReachable() -> Bool {
        return self.contains(.Reachable)
    }

    public func isConnectionRequired() -> Bool {
        return self.contains(.ConnectionRequired)
    }

    public func isInterventionRequired() -> Bool {
        return self.contains(.InterventionRequired)
    }

    public func isConnectionOnTraffic() -> Bool {
        return self.contains(.ConnectionOnTraffic)
    }

    public func isConnectionOnDemand() -> Bool {
        return self.contains(.ConnectionOnDemand)
    }

    func isConnectionOnTrafficOrDemand() -> Bool {
        return !self.intersect([.ConnectionOnTraffic, .ConnectionOnDemand]).isEmpty
    }

    public func isTransientConnection() -> Bool {
        return self.contains(.TransientConnection)
    }

    public func isLocalAddress() -> Bool {
        return self.contains(.IsLocalAddress)
    }

    public func isDirect() -> Bool {
        return self.contains(.IsDirect)
    }

    public func isConnectionRequiredOrTransient() -> Bool {
        let testcase:SCNetworkReachabilityFlags = [.ConnectionRequired, .TransientConnection]
        return self.intersect(testcase) == testcase
    }
}

public enum NetworkReachabilityErrorType: ErrorType {
    case UnableToSetCallback
    case UnableToSetDispatchQueue
    case FailedToCreateWithAddress(sockaddr_in)
    case FailedToCreateWithHostname(String)
}

public let kNetworkReachabilityChangedNotification = "com.cyberdev.swiftlets.networkReachability.changed"

func reachabilityCallback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) {
    let reachability = Unmanaged<NetworkReachability>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()

    dispatch_async(dispatch_get_main_queue()) {
        reachability.reachabilityChanged(flags)
    }
}

public class NetworkReachability {
    public typealias NetworkReachabilityClosure = () -> ()

    public enum Status: CustomStringConvertible {
        case None, WiFi, WWAN

        public var description: String {
            switch self {
            case .None:
                return NSLocalizedString("No Connection", comment:"NetworkReacability Status No Connection")
            case .WiFi:
                return NSLocalizedString("WiFi", comment:"NetworkReacability Status WiFi")
            case .WWAN:
                return NSLocalizedString("Cellular", comment:"NetworkReacability Status Cellular")
            }
        }
    }

    private var notifierRunning = false
    private var reachabilityRef: SCNetworkReachability?
    private let reachabilitySerialQueue = dispatch_queue_create("com.cyberdev.swiftlets.networkReachability", DISPATCH_QUEUE_SERIAL)

    public var statusChangeClosure: NetworkReachabilityClosure?
    public var reachableOnWWAN: Bool

    public var status: Status {
        if isReachable() {
            if isReachableViaWiFi() {
                return .WiFi
            }
            if NetworkReachabilityPlatform.isSimulator {
                return .WWAN
            }
        }
        return .None
    }

    private init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }

    private convenience init(hostname: String) throws {
        guard let hostnameCString = hostname.cStringUsingEncoding(NSUTF8StringEncoding),
            let ref = SCNetworkReachabilityCreateWithName(nil, hostnameCString) else {
            throw NetworkReachabilityErrorType.FailedToCreateWithHostname(hostname)
        }

        self.init(reachabilityRef: ref)
    }

    public class func reachabilityForHostName(hostname: String, changeNotification:NetworkReachabilityClosure) throws -> NetworkReachability {
        let result:NetworkReachability = try NetworkReachability(hostname: hostname)
        result.statusChangeClosure = changeNotification

        return result
    }

    public class func reachabilityForInternetConnection(changeNotification:NetworkReachabilityClosure) throws -> NetworkReachability {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let ref = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            throw NetworkReachabilityErrorType.FailedToCreateWithAddress(zeroAddress)
        }

        let result:NetworkReachability = NetworkReachability(reachabilityRef: ref)
        result.statusChangeClosure = changeNotification

        return result
    }

    public func startNotifier() throws {
        guard !notifierRunning else {
            return
        }

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

        if !SCNetworkReachabilitySetCallback(reachabilityRef!, reachabilityCallback, &context) {
            stopNotifier()
            throw NetworkReachabilityErrorType.UnableToSetCallback
        }

        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef!, reachabilitySerialQueue) {
            stopNotifier()
            throw NetworkReachabilityErrorType.UnableToSetDispatchQueue
        }

        dispatch_async(reachabilitySerialQueue) { () -> Void in
            self.reachabilityChanged(self.reachabilityFlags)
        }

        notifierRunning = true
    }

    public func stopNotifier() {
        defer {
            notifierRunning = false
        }

        self.statusChangeClosure = nil

        guard let reachabilityRef = reachabilityRef else {
            return
        }

        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }

    public func isReachable() -> Bool {
        return isReachableWithFlags(reachabilityFlags)
    }

    public func isReachableViaWWAN() -> Bool {
        return NetworkReachabilityPlatform.isSimulator && reachabilityFlags.isReachable() && reachabilityFlags.isOnWWAN()
    }

    public func isReachableViaWiFi() -> Bool {
        guard !NetworkReachabilityPlatform.isSimulator else {
            return true
        }

        guard !reachabilityFlags.isReachable() else {
            return false
        }

        return !reachabilityFlags.isOnWWAN()
    }

    private var lastKnownState: SCNetworkReachabilityFlags?
    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        guard lastKnownState != flags else {
            return
        }

        if let closure:NetworkReachabilityClosure = statusChangeClosure {
            closure()
        }

        NSNotificationCenter.defaultCenter().postNotificationName(kNetworkReachabilityChangedNotification, object:self)

        lastKnownState = flags
    }

    private func isReachableWithFlags(flags: SCNetworkReachabilityFlags) -> Bool {
        if !flags.isReachable() {
            return false
        }

        if flags.isConnectionRequiredOrTransient() {
            return false
        }

        if NetworkReachabilityPlatform.isSimulator {
            if flags.isOnWWAN() && !reachableOnWWAN {
                return false
            }
        }

        return true
    }

    private func isConnectionRequired() -> Bool {
        return reachabilityFlags.isConnectionRequired()
    }

    private func isConnectionOnDemand() -> Bool {
        return reachabilityFlags.isConnectionRequired() && reachabilityFlags.isConnectionOnTrafficOrDemand()
    }

    private func isInterventionRequired() -> Bool {
        return reachabilityFlags.isConnectionRequired() && reachabilityFlags.isInterventionRequired()
    }

    private var reachabilityFlags: SCNetworkReachabilityFlags {
        guard let reachabilityRef = reachabilityRef else {
            return SCNetworkReachabilityFlags()
        }

        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(&flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }

        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }

    deinit {
        stopNotifier()
    }
}
