//
//  AudioPlayerEngine.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/18/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import UIKit
import AVFoundation

//MARK: - Constants

//buffer configuration
fileprivate let kMaxBuffersInFlight:Int = 4
fileprivate let kBufferFrameCount:UInt32 = 64 * 1024

//interal indication track should begin at head
fileprivate let kTrackHeadFramePosition:AVAudioFramePosition = -1

///Watcher protocol for the AudioPlayerEngine class. All methods guaranteed to be called on main thread.
public protocol AudioPlayerEngineWatcher:class {
    func playbackStarted()
    func playbackPaused()
    func playbackStopped(trackCompleted:Bool)
}

///Simple class to playback audio files.
/// Supports seeking within track and notifies delegate of play/pause/stop state changes
public class AudioPlayerEngine {
    
    //MARK: - Member variables - private
    
    //AVAudioEngine and nodes
    internal var engine:AVAudioEngine = AVAudioEngine()
    internal var player:AVAudioPlayerNode = AVAudioPlayerNode()
    internal var audioFile:AVAudioFile?

    //seek position for start
    private var seekPosition:AVAudioFramePosition = kTrackHeadFramePosition
    
    //indication of external interruption of playback
    private var interrupted:Bool = false
    
    //state tracking for AVAudioPlayerNode pause
    private var paused:Bool = false
    private var pausedPosition:TimeInterval = 0.0
    
    //Buffer queue management and thread safety
    private let bufferQueue:DispatchQueue = DispatchQueue(label: "com.cyberdev.AudioPlayerEngine.buffers")
    private let bufferGroup:DispatchGroup = DispatchGroup()
    private var buffersInFlight:Int = 0

    //MARK: - Member variables - public
    
    //delegate for start/stop notifications
    weak public var delegate:AudioPlayerEngineWatcher?

    private(set) public var trackLength:TimeInterval = 0.0

    //playback position in seconds
    public var trackPosition:TimeInterval {
        get {
            //playing
            if let playerTime:AVAudioTime = currentPlayerTime() {
                return TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
            }
            //paused
            else if isPaused() {
                return self.pausedPosition
            }
            //stopped
            else if let currentAudioFile = self.audioFile {
                return TimeInterval(self.seekPosition/AVAudioFramePosition(currentAudioFile.fileFormat.sampleRate))
            }
            
            //not configured
            return 0.0
        }
        
        set(seconds) {
            guard let audioFile = self.audioFile else {
                return
            }
            
            let newPosition:AVAudioFramePosition = AVAudioFramePosition(seconds * audioFile.fileFormat.sampleRate)
            
            //if newPosition > audioFile.length then we are scheduling past end of file, allowing this for now as nothing bad happens

            let wasPlaying:Bool = self.isPlaying()
            if wasPlaying || isPaused() {
                _stop()
            }

            self.seekPosition = newPosition
            
            if wasPlaying {
                _play()
            }
        }
    }
    
    //playback postion as percentage 0.0->1.0
    public var trackProgress:Float {
        get {
            guard self.trackLength > 0.0 else {
                return 0.0
            }

            return Float(self.trackPosition/self.trackLength)
        }
        
        set(position) {
            //avoid position going negative
            let positionFloor = max(position, 0.0)
            let offsetSeconds:TimeInterval = self.trackLength * TimeInterval(positionFloor)
            self.trackPosition = offsetSeconds
        }
    }
    
    //MARK: - Initialization

    public init() {
        initAudioEngine()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func initAudioEngine () {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
        engine.prepare()
        if #available(iOS 11.0, *) {
            engine.isAutoShutdownEnabled = true
        }
    }
    
    //MARK: - Public Methods

    @discardableResult public func setTrack(url:NSURL) -> Bool {
        let wasPlaying:Bool = isPlaying()
        if wasPlaying {
            _stop()
        }
        
        do {
            self.audioFile = try AVAudioFile.init(forReading: url as URL)
            let processingFormat:AVAudioFormat = self.audioFile!.processingFormat
            self.trackLength = Double(self.audioFile!.length)/processingFormat.sampleRate
            self.seekPosition = kTrackHeadFramePosition

            registerForMediaServerNotifications()
            
            if wasPlaying {
                _play()
            }

            return true
        } catch let error as NSError {
            print("Exception in audio engine scheduleFile: \(error.localizedDescription)")
        }
        
        return false
    }
    
    public func isPlaying() -> Bool {
        return self.bufferQueue.sync {
            return self.player.isPlaying
        }
    }
    
    public func isPaused() -> Bool {
        return self.bufferQueue.sync {
            return self.paused
        }
    }
    
    @discardableResult public func play() -> Bool {
        let result:Bool
        
        if isPaused() {
            self.bufferQueue.sync {
                self.player.play()
                self.paused = false
            }
            result = true
        } else {
            result = _play()
        }
        
        if result {
            DispatchQueue.main.async {
                self.delegate?.playbackStarted()
            }
        }
        
        return result
    }

    public func pause() {
        guard isPlaying() else {
            return
        }

        let trackPosition = self.trackPosition

        self.bufferQueue.sync {
            self.player.pause()
            self.paused = true
            self.pausedPosition = trackPosition
        }
        
        DispatchQueue.main.async {
            self.delegate?.playbackPaused()
        }
    }
    
    public func stop() {
        guard isPlaying() else {
            return
        }
        
        let trackProgress:Float = self.trackProgress
        
        _stop()
        
        DispatchQueue.main.async {
            self.delegate?.playbackStopped(trackCompleted: trackProgress >= 1.0)
        }
    }
    
    ///Toggle play/pause as appropriate
    @discardableResult public func plause() -> Bool {
        if isPlaying() {
            pause()
        } else {
            play()
        }
        
        return isPlaying()
    }
    
    //MARK: - Private Methods
    
    @discardableResult private func _play() -> Bool {
        guard !self.isPlaying() else {
            return true
        }
        
        //check we are configured to play something
        guard let trackToPlay = self.audioFile, startEngine() else {
            return false
        }
        
        //If a seek offset is set then move track head to that position
        if self.seekPosition != kTrackHeadFramePosition {
            trackToPlay.framePosition = self.seekPosition
            initBuffers()
            
            self.bufferQueue.sync {
                if let currentPos:AVAudioFramePosition = self.player.lastRenderTime?.sampleTime {
                    let playTime:AVAudioTime = AVAudioTime(sampleTime: currentPos-self.seekPosition,
                        atRate: trackToPlay.processingFormat.sampleRate)
                    self.player.play(at: playTime)
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
            
            self.bufferQueue.sync {
                self.player.play()
            }
        }
        
        return self.isPlaying()
    }

    ///Stops engine, blocks until buffers are released
    private func _stop() {
        self.bufferQueue.sync {
            self.player.stop()
            self.paused = false
        }
        
        //wait for buffer queue to drain - block calling thread
        _ = self.bufferGroup.wait(timeout: DispatchTime.distantFuture)
        
        self.stopEngine()
    }

    //MARK: - Utility
    
    @discardableResult private func startEngine() -> Bool {
        guard !engine.isRunning else {
            return false
        }
        
        do {
            try engine.start()
        } catch let error as NSError {
            print("Exception in audio engine start: \(error.localizedDescription)")
        }
        
        return engine.isRunning
    }
    
    @discardableResult private func stopEngine() -> Bool {
        guard engine.isRunning else {
            return false
        }
        
        engine.stop()
        
        return !engine.isRunning
    }
    
    private func currentPlayerTime() -> AVAudioTime? {
        return self.bufferQueue.sync {
            guard let nodeTime:AVAudioTime = self.player.lastRenderTime else {
                return nil
            }
            
            return self.player.playerTime(forNodeTime: nodeTime)
        }
    }
    
    //MARK: - Audio buffer handling
    
    private func initBuffers() {
        guard let audioFile = self.audioFile else {
            return
        }
        
        for _ in 1...kMaxBuffersInFlight {
            guard let buffer:AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: kBufferFrameCount) else {
                return
            }
            self.scheduleBuffer(buffer: buffer)
        }
    }
    
    @discardableResult private func scheduleBuffer(buffer:AVAudioPCMBuffer) -> Bool {
        return self.bufferQueue.sync {
            //Fill next buffer from file
            guard self.readNextBuffer(buffer: buffer) else {
                return false
            }
            
            self.bufferGroup.enter()
            self.buffersInFlight += 1
            
            //schedule buffer for playback at end of player queue
            self.player.scheduleBuffer(buffer) { () -> Void in
                let bufferQueueExhausted:Bool = self.bufferQueue.sync {
                    self.buffersInFlight -= 1
                    self.bufferGroup.leave()
                    return self.buffersInFlight <= 0
                }
                
                //If we are still playing reschedule this buffer or stop if at end of file
                if self.isPlaying() {
                    if bufferQueueExhausted {
                        self.stop()
                    } else {
                        //to understand recursion one must first understand recursion
                        self.scheduleBuffer(buffer: buffer)
                    }
                }
            }
            
            return true
        }
    }
    
    private func readNextBuffer(buffer:AVAudioPCMBuffer) -> Bool {
        guard let audioFile = self.audioFile, audioFile.framePosition < audioFile.length else {
            return false
        }
        
        do {
            try audioFile.read(into: buffer)
            return buffer.frameLength > 0
        } catch let error as NSError {
            print("Exception in buffer read: \(error.localizedDescription)")
            return false
        }
    }

    //MARK: - Session notificaiton handling
    
    private func registerForMediaServerNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioSessionInterruption, object: nil, queue: nil) { [weak self] (notification:Notification) in
            guard let why:AVAudioSessionInterruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSessionInterruptionType else {
                return
            }
            
            switch why {
            case .began:
                self?.interruptSessionBegin()
            case .ended:
                self?.interruptSessionEnd()
            }
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionMediaServicesWereLost, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioSessionMediaServicesWereLost, object: nil, queue: nil) { /*[weak self]*/ (notification:Notification) in
            //TODO: Reset everything here
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionMediaServicesWereReset, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioSessionMediaServicesWereReset, object: nil, queue: nil) { /*[weak self]*/ (notification:Notification) in
            //TODO: Reset everything here
        }
    }
    
    private func interruptSessionBegin() {
        guard let nodeTime:AVAudioTime = self.player.lastRenderTime,
            let playerTime:AVAudioTime = self.player.playerTime(forNodeTime: nodeTime) else {
            return
        }
        
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

//TimePitch Rate constants
fileprivate let kRateCenter:Float = 1.0
fileprivate let kRateDetentRange:Float = 0.025

//Track output level constants
fileprivate let kOutputLevelDefault:Float = 0.0
fileprivate let kOutputLevelDetentRange:Float = 0.25

//Equalizer constants
fileprivate let kNumberOfBands:Int = 4
fileprivate let kLowShelfInitialFrequency:Float = 20.0
fileprivate let kParametricLowInitialFrequency:Float = 200.0
fileprivate let kParametricHighInitialFrequency:Float = 2000.0
fileprivate let kHighShelfInitialFrequency:Float = 20000.0
fileprivate let kEQGainDetentRange:Float = 0.5

///AudioPlayerEngine subclass that adds time rate control, four band parametric EQ, and simple output routing
public class FXAudioPlayerEngine: AudioPlayerEngine {
    
    public enum OutputRouting {
        case Stereo
        case Mono
        case MonoLeft
        case MonoRight
    }
    
    //Audio Units
    private let timePitch:AVAudioUnitTimePitch = AVAudioUnitTimePitch()
    private let equalizer:AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: kNumberOfBands)
    private let routingMixer:AVAudioMixerNode = AVAudioMixerNode()

    //MARK: - Member variables - public
    
    public var outputSampleRate:Double {
        get {
            return self.engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        }
    }
    
    public var outputRouting:OutputRouting = .Stereo {
        didSet {
            guard outputRouting != oldValue else {
                return
            }
            
            guard let monoLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono) else {
                return
            }
            
            engine.disconnectNodeOutput(routingMixer)
            let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            let monoFormat = AVAudioFormat(commonFormat:outputFormat.commonFormat,
                sampleRate: outputFormat.sampleRate,
                interleaved: outputFormat.isInterleaved,
                channelLayout: monoLayout)

            switch outputRouting {
            case .Stereo:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: outputFormat)
                routingMixer.pan = 0.0
                
            case .Mono:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = 0.0

            case .MonoLeft:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = -1.0
                
            case .MonoRight:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = 1.0
            }
        }
    }
    
    ///Adjust track playback levels in range: -1.0 to 1.0
    ///A detent around zero is automatically applied
    public var trackOutputLevelAdjust:Float = kOutputLevelDefault {
        didSet {
            var adjustment:Float = trackOutputLevelAdjust
            //apply detent around zero
            if fabs(adjustment) <= kOutputLevelDetentRange {
                adjustment = kOutputLevelDefault
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
            let centerOffset:Float = fabs(kRateCenter - fabs(rate))
            if centerOffset <= kRateDetentRange {
                timePitch.rate = kRateCenter
            } else {
                timePitch.rate = rate
            }
        }
    }
    
    ///Array of EQ filter parameters
    public var equalizerBands:[AudioUnitEQFilterParameters] {
        get {
            return equalizer.bands.map { (band) -> AudioUnitEQFilterParameters in
                AudioUnitEQFilterParameters(filter: band)
            }
        }
        
        set(bands) {
            for (index, band) in bands.enumerated() {
                setFilterAtIndex(filterIndex: index, filter: band)
            }
        }
    }
    
    //MARK: - Init
    
    override public init() {
        super.init()
    }
    
    override internal func initAudioEngine () {
        //super first so it will setup player, etc.
        super.initAudioEngine()
        
        //configure time pitch
        timePitch.bypass = false
        engine.attach(timePitch)
        
        //configure eq
        equalizer.bypass = false
        equalizer.globalGain = 0.0
        engine.attach(equalizer)
        normalizeEQ()
        
        //configure mixer
        engine.attach(routingMixer)

        //disconnect player so we can insert our effects between player and output
        engine.disconnectNodeOutput(player)
        
        //format of output
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)

        //construct node graph
        engine.connect(player, to: timePitch, format: outputFormat)
        engine.connect(timePitch, to: equalizer, format: outputFormat)
        engine.connect(equalizer, to: routingMixer, format: outputFormat)
        engine.connect(routingMixer, to: engine.mainMixerNode, format: outputFormat)

        //configure gain structure
        self.trackOutputLevelAdjust = kOutputLevelDefault

        //prepare the engine
        engine.prepare()
    }
    
    //MARK: - Public Methods
    
    ///Reset EQ, track output level, and time pitch effect to nominal values.
    public func normalize() {
        normalizeEQ()
        trackOutputLevelAdjust = kOutputLevelDefault
        timePitchRate = kRateCenter
    }

    ///Reset EQ to nominal (flat) values
    public func normalizeEQ() {
        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = kLowShelfInitialFrequency
        equalizer.bands[0].gain = 0.0
        equalizer.bands[0].bypass = false
        
        equalizer.bands[1].filterType = .parametric
        equalizer.bands[1].frequency = kParametricLowInitialFrequency
        equalizer.bands[1].gain = 0.0
        equalizer.bands[1].bandwidth = 1.0
        equalizer.bands[1].bypass = false
        
        equalizer.bands[2].filterType = .parametric
        equalizer.bands[2].frequency = kParametricHighInitialFrequency
        equalizer.bands[2].gain = 0.0
        equalizer.bands[2].bandwidth = 1.0
        equalizer.bands[2].bypass = false
        
        equalizer.bands[3].filterType = .highShelf
        equalizer.bands[3].frequency = kHighShelfInitialFrequency
        equalizer.bands[3].gain = 0.0
        equalizer.bands[3].bypass = false
    }
    
    ///Adjust EQ filter at given index to given set of filter parameters
    public func setFilterAtIndex(filterIndex:Int, filter:AudioUnitEQFilterParameters) {
        equalizer.bands[filterIndex].filterType = filter.filterType
        setFilterAtIndex(filterIndex: filterIndex, frequency: filter.frequency, gain: filter.gain, bandwidth: filter.bandwidth)
    }
    
    ///Adjust EQ filter at given index to given set of filter parameters
    public func setFilterAtIndex(filterIndex:Int, frequency:Float , gain:Float, bandwidth:Float = 0.0) {
        equalizer.bands[filterIndex].frequency = frequency
        
        if fabs(gain) <= kEQGainDetentRange {
            equalizer.bands[filterIndex].gain = 0.0
        } else {
            equalizer.bands[filterIndex].gain = gain
        }
        
        if bandwidth > 0.0 {
            equalizer.bands[filterIndex].bandwidth = bandwidth
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
    
    public init(filter:AVAudioUnitEQFilterParameters) {
        self.filterType = filter.filterType
        self.frequency = filter.frequency
        self.bandwidth = filter.bandwidth
        self.gain = filter.gain
        self.bypass = filter.bypass
        
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.filterType = AVAudioUnitEQFilterType(rawValue: aDecoder.decodeInteger(forKey: "filterType"))!
        self.frequency = aDecoder.decodeFloat(forKey: "frequency")
        self.bandwidth = aDecoder.decodeFloat(forKey: "bandwidth")
        self.gain = aDecoder.decodeFloat(forKey: "gain")
        self.bypass = aDecoder.decodeBool(forKey: "bypass")

        super.init()
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.filterType.rawValue, forKey: "filterType")
        aCoder.encode(self.frequency, forKey: "frequency")
        aCoder.encode(self.bandwidth, forKey: "bandwidth")
        aCoder.encode(self.gain, forKey: "gain")
        aCoder.encode(self.bypass, forKey: "bypass")
    }
    
    override public var description : String {
        return "AudioUnitEQFilterParameters:\nfilterType:\(self.filterType)\nfrequency:\(self.frequency)\nbandwidth:\(self.bandwidth)\ngain:\(self.gain)\nbypass:\(self.bypass)"
    }
    
    override public var debugDescription : String {
        return "AudioUnitEQFilterParameters:\nfilterType:\(self.filterType)\nfrequency:\(self.frequency)\nbandwidth:\(self.bandwidth)\ngain:\(self.gain)\nbypass:\(self.bypass)"
    }
}
