//
//  AudioEngine.swift
//  Segues
//
//  Created by Frank Vernon on 7/18/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import UIKit
import AVFoundation

///Watcher protocol for the AudioPlayerEngine class. All methods guaranteed to be called on main thread.
public protocol AudioPlayerEngineWatcher:class {
    func playbackStarted()
    func playbackStopped(trackCompleted:Bool)
}

///Simple class to playback audio files.
/// Supports seeking within track and notifies delegates of play/stop state changes
public class AudioPlayerEngine: NSObject {
    //MARK: - Constants
    
    //buffer configuration
    private let kMaxBuffersInFlight:Int = 4
    private let kBufferFrameCount:UInt32 = 64 * 1024
    
    //interal indication track should begin at head
    private let kTrackHeadFramePosition:AVAudioFramePosition = -1
    
    //MARK: - Member variables - private
    
    //AVAudioEngine and nodes
    private var engine:AVAudioEngine = AVAudioEngine()
    private var player:AVAudioPlayerNode!
    private var audioFile:AVAudioFile?

    //seek position for next start
    private var seekPosition:AVAudioFramePosition
    
    //indication of external interruption of playback
    private var interrupted:Bool = false
    
    //Buffer queue management and thread safety
    private let bufferQueue:gcd.serial = gcd.serial(label: "com.cyberdev.AudioPlayerEngine.buffers")
    private let bufferGroup:gcd.group = gcd.group()
    private var buffersInFlight:Int = 0

    //MARK: - Member variables - public
    
    //delegate for start/stop notifications
    weak public var delegate:AudioPlayerEngineWatcher?

    private var _trackLength:NSTimeInterval = 0.0
    public var trackLength:NSTimeInterval {
        get {
            return _trackLength
        }
    }

    //playback position in seconds
    public var trackPosition:NSTimeInterval {
        get {
            var result:NSTimeInterval = 0.0
            if self.isPlaying() {
                if let playerTime:AVAudioTime = currentPlayerTime() {
                    result = Double(playerTime.sampleTime) / playerTime.sampleRate
                }
            } else if let currentAudioFile = self.audioFile {
                result = NSTimeInterval(self.seekPosition/AVAudioFramePosition(currentAudioFile.fileFormat.sampleRate))
            }
            return result
        }
        
        set(seconds) {
            if let currentAudioFile = self.audioFile {
                let wasPlaying:Bool = self.isPlaying()
                if wasPlaying {
                    _stop()
                }
                
                self.seekPosition = AVAudioFramePosition(seconds * currentAudioFile.fileFormat.sampleRate)
                
                if wasPlaying {
                    _play()
                }
            }
        }
    }
    
    //playback postion as percentage 0.0->1.0
    public var trackProgress:Float {
        get {
            var result:Float = 0
            if self.trackLength > 0 {
                result = Float(self.trackPosition/self.trackLength)
            }
            return result
        }
        
        set(position) {
            let offsetSeconds:NSTimeInterval = self.trackLength * NSTimeInterval(position)
            self.trackPosition = offsetSeconds
        }
    }
    
    //MARK: - Init

    override public init() {
        self.seekPosition = kTrackHeadFramePosition

        super.init()
        
        initAudioEngine()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initAudioEngine () {
        player = AVAudioPlayerNode()
        engine.attachNode(player)
        
        let format = engine.mainMixerNode.outputFormatForBus(0)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        engine.prepare()
    }
    
    //MARK: - Public Methods

    public func setTrack(url:NSURL) -> Bool {
        let wasPlaying:Bool = isPlaying()
        if wasPlaying {
            _stop()
        }
        
        do {
            self.audioFile = try AVAudioFile.init(forReading: url)
            let processingFormat:AVAudioFormat = self.audioFile!.processingFormat
            self._trackLength = Double(self.audioFile!.length)/processingFormat.sampleRate
            self.seekPosition = kTrackHeadFramePosition

            registerForMediaServerNotifications()
            
            if wasPlaying {
                _play()
            }

            return true;
        } catch let error as NSError {
            print("Exception in audio engine scheduleFile: \(error.localizedDescription)")
        }
        
        return false;
    }
    
    public func isPlaying() -> Bool {
        var result:Bool = false
        self.bufferQueue.sync { () -> () in
            result = self.player.playing
        }
        
        return result;
    }

    public func play() -> Bool {
        if _play() {
            gcd.main().async({ () -> () in
                if let delegate = self.delegate {
                    delegate.playbackStarted()
                }
            })
            
            return true;
        }
        
        return false;
    }

    public func pause() {
        if isPlaying() {
            let now:NSTimeInterval = self.trackPosition
            stop()
            self.trackPosition = now
        }
    }
    
    public func plause() -> Bool {
        if isPlaying() {
            pause()
        } else {
            play()
        }
        
        return isPlaying()
    }

    public func stop() {
        if isPlaying() {
            let progress:Float = self.trackProgress
            _stop()
            gcd.main().async({ () -> () in
                if let delegate = self.delegate {
                    delegate.playbackStopped(progress >= 1.0)
                }
            })
        }
    }

    //MARK: - Private Methods
    
    private func _play() -> Bool {
        if self.isPlaying() {
            return true
        }
        
        //check we are configured to play something
        if let trackToPlay = self.audioFile {
            //start the engine if necesssary
            if !startEngine() {
                return false
            }
            
            //If a seek offset is set then move track head to that position
            if self.seekPosition != kTrackHeadFramePosition {
                trackToPlay.framePosition = self.seekPosition
                initBuffers()
                
                self.bufferQueue.sync { () -> Void in
                    if let currentPos:AVAudioFramePosition = self.player.lastRenderTime?.sampleTime {
                        let playTime:AVAudioTime = AVAudioTime(sampleTime: currentPos-self.seekPosition,
                            atRate: trackToPlay.processingFormat.sampleRate)
                        self.player.playAtTime(playTime)
                    }
                }
                
                //reset seek position now that it has been consumed
                self.seekPosition = kTrackHeadFramePosition
            }
                
            //otherwise just start playing at beginning of track
            else {
                //ensure file framePosition at head in case we are re-playing a track
                trackToPlay.framePosition = 0
                initBuffers()
                
                self.bufferQueue.sync({ () -> () in
                    self.player.play()
                })
            }
        } else {
            return false
        }
        
        return self.isPlaying()
    }

    private func _stop() {
        self.bufferQueue.sync { () -> () in
            self.player.stop()
        }
        
        //wait for buffer queue to drain
        self.bufferGroup.wait()
    }

    //MARK: - Utility
    
    private func startEngine() -> Bool {
        if !engine.running {
            do {
                try engine.start()
            } catch let error as NSError {
                print("Exception in audio engine start: \(error.localizedDescription)")
            }
        }

        return engine.running
    }
    
    private func currentPlayerTime() -> AVAudioTime? {
        var result:AVAudioTime? = nil
        
        self.bufferQueue.sync { () -> () in
            if let nodeTime:AVAudioTime = self.player.lastRenderTime {
                result = self.player.playerTimeForNodeTime(nodeTime)
            }
        }
        
        return result
    }
    
    //MARK: - Audio buffer handling
    
    private func initBuffers() {
        for _ in 1...self.kMaxBuffersInFlight {
            if let buffer:AVAudioPCMBuffer = AVAudioPCMBuffer(PCMFormat: self.audioFile!.processingFormat, frameCapacity: self.kBufferFrameCount) {
                self.scheduleBuffer(buffer)
            }
        }
    }
    
    private func scheduleBuffer(buffer:AVAudioPCMBuffer) -> Bool {
        var result:Bool = false
        
        self.bufferQueue.sync { () -> () in
            //Fill next buffer from file
            if self.readNextBuffer(buffer) {
                self.bufferGroup.enter()
                ++self.buffersInFlight
                
                //schedule buffer for playback at end of player queue
                self.player.scheduleBuffer(buffer) { () -> Void in
                    var bufferQueueExhausted:Bool = false
                    self.bufferQueue.sync({ () -> () in
                        --self.buffersInFlight
                        self.bufferGroup.leave()
                        bufferQueueExhausted = self.buffersInFlight <= 0
                    })
                    
                    //Reschedule buffer or stop if at end of file
                    if self.isPlaying() {
                        if bufferQueueExhausted {
                            self.stop()
                        } else {
                            self.scheduleBuffer(buffer)
                        }
                    }
                }
                result = true
            }
        }
        
        return result
    }
    
    private func readNextBuffer(buffer:AVAudioPCMBuffer) -> Bool {
        do {
            try self.audioFile?.readIntoBuffer(buffer)
        } catch let error as NSError {
            print("Exception in buffer read: \(error.localizedDescription)")
        }

        return buffer.frameLength > 0
    }

    //MARK: - Session notificaiton handling
    
    private func registerForMediaServerNotifications() {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionInterruptionNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionNotification", name: AVAudioSessionInterruptionNotification, object: nil)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionMediaServicesWereLostNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "serverStoppedNotification", name: AVAudioSessionMediaServicesWereLostNotification, object: nil)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVAudioSessionMediaServicesWereResetNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "serverRestartNotification", name: AVAudioSessionMediaServicesWereResetNotification, object: nil)
    }
    
    private func sessionNotification(notification:NSNotification) {
        let why : AnyObject? = notification.userInfo?[AVAudioSessionInterruptionTypeKey]
        if let why = why as? UInt {
            if let why = AVAudioSessionInterruptionType(rawValue: why) {
                switch why {
                case .Began:
                    interruptSessionBegin()
                case .Ended:
                    interruptSessionEnd()
                }
            }
        }
    }
    
    private func serverStoppedNotification(notification:NSNotification) {
        //TODO: Reset everything here
    }
    
    private func serverRestartNotification(notification:NSNotification) {
        //TODO: restart playback?
    }

    private func interruptSessionBegin() {
        let nodeTime:AVAudioTime = self.player.lastRenderTime!
        let playerTime:AVAudioTime = self.player.playerTimeForNodeTime(nodeTime)!
        
        self.interrupted = true
        self.seekPosition = playerTime.sampleTime
        
        pause()
        
        self.engine.stop()
    }
    
    private func interruptSessionEnd() {
        if self.interrupted {
            play()
        }
    }
}

//MARK: - FXAudioPlayerEngine

///AudioPlayerEngine subclass that adds time rate control, four band parametric EQ, and simple output routing
public class FXAudioPlayerEngine: AudioPlayerEngine {
    
    public enum OutputRouting {
        case Stereo
        case MonoLeft
        case MonoRight
        case MonoLeftRight
    }
    
    //TimePitch Rate constants
    private static let kRateCenter:Float = 1.0
    private static let kRateDetentRange:Float = 0.025
    
    //Track output level constants
    private static let kOutputLevelDefault:Float = 0.0
    private static let kOutputLevelDetentRange:Float = 0.25

    //EQ initial frequencies
    private static let kLowShelfInitialFrequency:Float = 20.0
    private static let kParametricLowInitialFrequency:Float = 200.0
    private static let kParametricHighInitialFrequency:Float = 2000.0
    private static let kHighShelfInitialFrequency:Float = 20000.0
    private static let kEQGainDetentRange:Float = 0.5
    

    private var timePitch:AVAudioUnitTimePitch!
    private var equalizer:AVAudioUnitEQ!
    private var routingMixer:AVAudioMixerNode!

    //MARK: - Member variables - public
    
    public var outputSampleRate:Double {
        get {
            return self.engine.mainMixerNode.outputFormatForBus(0).sampleRate
        }
    }
    
    public var outputRouting:OutputRouting = .Stereo {
        didSet {
            if outputRouting != oldValue {
                engine.disconnectNodeOutput(routingMixer)
                let outputFormat = engine.mainMixerNode.outputFormatForBus(0)
                let monoFormat = AVAudioFormat(commonFormat:outputFormat.commonFormat,
                    sampleRate: outputFormat.sampleRate,
                    interleaved: outputFormat.interleaved,
                    channelLayout: AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono))

                switch outputRouting {
                case .Stereo:
                    engine.connect(routingMixer, to: engine.mainMixerNode, format: outputFormat)
                    routingMixer.pan = 0.0
                    
                case .MonoLeft:
                    engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                    routingMixer.pan = -1.0
                    
                case .MonoRight:
                    engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                    routingMixer.pan = 1.0

                case .MonoLeftRight:
                    engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                    routingMixer.pan = 0.0
                }
            }
        }
    }
    
    ///Adjust track playback levels in range: -1.0 to 1.0
    ///A detent around zero is automatically applied
    public var trackOutputLevelAdjust:Float = FXAudioPlayerEngine.kOutputLevelDefault {
        didSet {
            var adjustment:Float = trackOutputLevelAdjust
            //apply detent around zero
            if fabs(adjustment) <= FXAudioPlayerEngine.kOutputLevelDetentRange {
                adjustment = FXAudioPlayerEngine.kOutputLevelDefault
            }
            engine.mainMixerNode.outputVolume = (adjustment + 1.0)/2.0
        }
    }
    
    ///Adjust the time pitch rate in the range: 0.03125 to 32.0, default is 1.0
    ///A detent around 1.0 is automatically applied
    public var timePitchRate:Float {
        get {
            return timePitch.rate
        }
        
        set(rate) {
            let centerOffset:Float = fabs(FXAudioPlayerEngine.kRateCenter - fabs(rate))
            if centerOffset <= FXAudioPlayerEngine.kRateDetentRange {
                timePitch.rate = FXAudioPlayerEngine.kRateCenter
            } else {
                timePitch.rate = rate
            }
        }
    }
    
    ///Array of EQ filter parameters
    public var equalizerBands:[AudioUnitEQFilterParameters] {
        get {
            var result:[AudioUnitEQFilterParameters] = [AudioUnitEQFilterParameters]()
            for band:AVAudioUnitEQFilterParameters in equalizer.bands {
                result.append(AudioUnitEQFilterParameters(filter: band))
            }
            return result
        }
        
        set(bands) {
            for (index, band) in bands.enumerate() {
                setFilterAtIndex(index, filter: band)
            }
        }
    }
    
    //MARK: - Init
    
    override public init() {
        super.init()
    }
    
    override private func initAudioEngine () {
        //super first so it will setup player, etc.
        super.initAudioEngine()
        
        //configure time pitch
        timePitch = AVAudioUnitTimePitch()
        timePitch.bypass = false
        engine.attachNode(timePitch)
        
        //configure eq
        equalizer = AVAudioUnitEQ(numberOfBands: 4)
        equalizer.globalGain = 0.0
        equalizer.bypass = false
        engine.attachNode(equalizer)
        normalizeEQ()
        
        //configure mixer
        routingMixer = AVAudioMixerNode()
        engine.attachNode(routingMixer)

        //disconnect player so we can insert our effects between player and output
        engine.disconnectNodeOutput(player);
        
        //format of output
        let outputFormat = engine.mainMixerNode.outputFormatForBus(0)

        //construct node graph
        engine.connect(player, to: timePitch, format: outputFormat)
        engine.connect(timePitch, to: equalizer, format: outputFormat)
        engine.connect(equalizer, to: routingMixer, format: outputFormat)
        engine.connect(routingMixer, to: engine.mainMixerNode, format: outputFormat)

        //configure gain structure
        self.trackOutputLevelAdjust = FXAudioPlayerEngine.kOutputLevelDefault

        //prepare the engine
        engine.prepare()
    }
    
    //MARK: - Public Methods
    
    ///Reset EQ, track output level, and time pitch effect to nominal values.
    public func normalize() {
        normalizeEQ()
        trackOutputLevelAdjust = FXAudioPlayerEngine.kOutputLevelDefault
        timePitchRate = FXAudioPlayerEngine.kRateCenter
    }

    ///Reset EQ to nominal (flat) values
    public func normalizeEQ() {
        equalizer.bands[0].filterType = .LowShelf
        equalizer.bands[0].frequency = FXAudioPlayerEngine.kLowShelfInitialFrequency
        equalizer.bands[0].gain = 0.0
        equalizer.bands[0].bypass = false
        
        equalizer.bands[1].filterType = .Parametric
        equalizer.bands[1].frequency = FXAudioPlayerEngine.kParametricLowInitialFrequency
        equalizer.bands[1].gain = 0.0
        equalizer.bands[1].bandwidth = 1.0
        equalizer.bands[1].bypass = false
        
        equalizer.bands[2].filterType = .Parametric
        equalizer.bands[2].frequency = FXAudioPlayerEngine.kParametricHighInitialFrequency
        equalizer.bands[2].gain = 0.0
        equalizer.bands[2].bandwidth = 1.0
        equalizer.bands[2].bypass = false
        
        equalizer.bands[3].filterType = .HighShelf
        equalizer.bands[3].frequency = FXAudioPlayerEngine.kHighShelfInitialFrequency
        equalizer.bands[3].gain = 0.0
        equalizer.bands[3].bypass = false
    }
    
    ///Adjust EQ filter at given index to given set of filter parameters
    public func setFilterAtIndex(filterIndex:Int, filter:AudioUnitEQFilterParameters) {
        equalizer.bands[filterIndex].filterType = filter.filterType;
        setFilterAtIndex(filterIndex, frequency: filter.frequency, gain: filter.gain, bandwidth: filter.bandwidth)
    }
    
    ///Adjust EQ filter at given index to given set of filter parameters
    public func setFilterAtIndex(filterIndex:Int, frequency:Float , gain:Float, bandwidth:Float = 0.0) {
        equalizer.bands[filterIndex].frequency = frequency;
        
        if fabs(gain) <= FXAudioPlayerEngine.kEQGainDetentRange {
            equalizer.bands[filterIndex].gain = 0.0;
        } else {
            equalizer.bands[filterIndex].gain = gain;
        }
        
        if bandwidth > 0.0 {
            equalizer.bands[filterIndex].bandwidth = bandwidth;
        }
    }
}

///Wrapup class for EQ settings... these map directly to AVAudioUnitEQFilterParameters which is not copyable/fungable
public class AudioUnitEQFilterParameters: NSObject, NSCoding {
    
    //Properties from AVAudioUnitEQFilterParameters
    public var filterType:AVAudioUnitEQFilterType
    public var frequency:Float
    public var bandwidth:Float
    public var gain:Float
    public var bypass:Bool
    
    @objc public init(filter:AVAudioUnitEQFilterParameters) {
        self.filterType = filter.filterType
        self.frequency = filter.frequency
        self.bandwidth = filter.bandwidth
        self.gain = filter.gain
        self.bypass = filter.bypass
        
        super.init()
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        self.filterType = AVAudioUnitEQFilterType(rawValue: aDecoder.decodeIntegerForKey("filterType"))!
        self.frequency = aDecoder.decodeFloatForKey("frequency")
        self.bandwidth = aDecoder.decodeFloatForKey("bandwidth")
        self.gain = aDecoder.decodeFloatForKey("gain")
        self.bypass = aDecoder.decodeBoolForKey("bypass")

        super.init()
    }
    
    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self.filterType.rawValue, forKey: "filterType")
        aCoder.encodeFloat(self.frequency, forKey: "frequency")
        aCoder.encodeFloat(self.bandwidth, forKey: "bandwidth")
        aCoder.encodeFloat(self.gain, forKey: "gain")
        aCoder.encodeBool(self.bypass, forKey: "bypass")
    }
    
    override public var description : String {
        return "AudioUnitEQFilterParameters:\nfilterType:\(self.filterType)\nfrequency:\(self.frequency)\nbandwidth:\(self.bandwidth)\ngain:\(self.gain)\nbypass:\(self.bypass)"
    }
    
    override public var debugDescription : String {
        return "AudioUnitEQFilterParameters:\nfilterType:\(self.filterType)\nfrequency:\(self.frequency)\nbandwidth:\(self.bandwidth)\ngain:\(self.gain)\nbypass:\(self.bypass)"
    }
}