//
//  AVAudioSession+Routing.swift
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
    /// overall list of channels for the route of the associated session. This returns the index value
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
    ///Struct for mapping the output of an AVAudioOutputNode
    ///to a channel on the current route of the session.
    struct OutputChannelMapping {
        var output: Int
        var channel: AVAudioSessionChannelDescription
        
        public init(output: Int, channel: AVAudioSessionChannelDescription) {
            self.output = output
            self.channel = channel
        }
    }

    /// Map outputs on this AU to channels from the given session.
    ///
    /// Lists of ports (i.e. devices) and associated channels can be obtained via: AVAudioSession.currentRoute
    ///
    ///  - note: See https://developer.apple.com/forums/thread/15416
    func mapRouteOutputs(to channels: [OutputChannelMapping],
                         for session: AVAudioSession = AVAudioSession.sharedInstance()) {
        guard let outputAudioUnit = audioUnit else {
            return
        }
        
        //Initialize array with '-1'. These are the output positions which will be ignored
        // in the assignment of channels.
        var channelMap: [Int32] = Array<Int32>(count: session.currentRouteChannelCount) {_ in -1}
        
        //Populate the map with output channels at the associated channel indexes.
        for channel in channels {
            channelMap[session.outputIndexFor(channel: channel.channel)] = Int32(channel.output)
        }
        
        //Set the property on the AU
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
    ///I've encountered ports with trailing white space so this cleans
    /// up the name to be more presentable to users.
    var shortPortName: String {
        portName.stringByTrimmingWhiteSpace()
    }
}

public extension AVAudioSessionChannelDescription {
    ///Name of the channel with the associated port name stripped.
    var shortChannelName: String {
        guard let portName = AVAudioSession.sharedInstance().portFor(uid: owningPortUID)?.portName else {
            return channelName
        }
        return channelName.stringByTrimmingPrefix(portName).stringByTrimmingWhiteSpace()
    }
    
    ///Index of channel on the current route. Used for mapping outputs to channels.
    var outputIndex: Int {
        AVAudioSession.sharedInstance().outputIndexFor(channel: self)
    }
}
