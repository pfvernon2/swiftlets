//
//  AVAudioSession+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 3/9/22.
//  Copyright © 2022 Frank Vernon. All rights reserved.
//

import AVFoundation

public extension AVAudioSession {
    func portFor(uid: String) -> AVAudioSessionPortDescription? {
        currentRoute.outputs.filter {$0.uid == uid}.first
    }
    
    /// Channels on outputs are mapped to AVAudioOutputNodes via the channel index position in the
    /// overall list of outputs for the route of the associated session. This function returns the index value
    /// for a given channel on current route of the given session.
    ///
    /// Reference: https://developer.apple.com/forums/thread/15416
    func outputIndexFor(channel target: AVAudioSessionChannelDescription) -> Int {
        var result: Int = 0
        outputLoop: for output in currentRoute.outputs {
            guard let channels = output.channels else {
                continue
            }
            
            for channel in channels {
                if channel == target {
                    break outputLoop
                }
                result += 1
            }
        }
        
        return result
    }
    
    ///Total number of channels for all outputs on the current route
    var currentRouteChannelCount: Int {
        currentRoute.outputs.reduce(into: 0) {$0 += $1.channels?.count ?? 0}
    }
    
    var currentRouteDescription: String {
        currentRoute.outputs.compactMap { device in
            device.channels?.map {"\(device.shortPortName) \($0.shortChannelName)"}
        }.flatMap{$0}.joined(separator: "\n")
    }
}

public extension AVAudioOutputNode {
    struct OutputChannelMapping {
        var output: Int
        var channel: AVAudioSessionChannelDescription
        
        public init(output: Int, channel: AVAudioSessionChannelDescription) {
            self.output = output
            self.channel = channel
        }
    }

    /// Map channels on this output to channels from the given session.
    ///
    /// Lists of outputs and associated channels can be obtained via: AVAudioSession.currentRoute
    ///
    ///  - note: See https://developer.apple.com/forums/thread/15416
    func mapRouteOutputs(to channels: [OutputChannelMapping],
                         for session: AVAudioSession = AVAudioSession.sharedInstance()) {
        guard let outputAudioUnit = audioUnit else {
            return
        }
        
        //populate array with '-1'. These are the output positions which will be ignored
        // in the assignment of channels
        var channelMap: [Int32] = Array<Int32>(count: session.currentRouteChannelCount) {_ in -1}
        
        for channel in channels {
            channelMap[session.outputIndexFor(channel: channel.channel)] = Int32(channel.output)
        }
        
        let propSize: UInt32 = UInt32(channelMap.count) * UInt32(MemoryLayout<Int32>.size)
        AudioUnitSetProperty(outputAudioUnit,
                             kAudioOutputUnitProperty_ChannelMap,
                             kAudioUnitScope_Global,
                             0,
                             channelMap,
                             propSize);
    }
}

public extension AVAudioSessionPortDescription {
    var shortPortName: String {
        portName.stringByTrimmingWhiteSpace()
    }
}

public extension AVAudioSessionChannelDescription {
    //Name of the channel with the associated port name stripped.
    var shortChannelName: String {
        guard let portName = AVAudioSession.sharedInstance().portFor(uid: owningPortUID)?.portName else {
            return channelName
        }
        return channelName.stringByTrimmingPrefix(portName).stringByTrimmingWhiteSpace()
    }
    
    var outputIndex: Int {
        AVAudioSession.sharedInstance().outputIndexFor(channel: self)
    }
}
