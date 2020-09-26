//
//  AudioPlayerEngine.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/18/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import AVFoundation

//MARK: - AudioPlayerDelegate

///Watcher protocol for the AudioPlayerEngine class. All methods guaranteed to be called on main thread.
public protocol AudioPlayerDelegate: class {
    func playbackStarted()
    func playbackPaused()
    func playbackStopped(trackCompleted: Bool)
    func playbackRateAdjusted()
}

//MARK: - Constants

//buffer configuration
fileprivate let kMaxBuffersInFlight: Int = 4
fileprivate let kBufferFrameCount: UInt32 = 64 * 1024

//internal indication track should begin at head
fileprivate let kTrackHeadFramePosition: AVAudioFramePosition = -1

//MARK: - AudioPlayerEngine

///Simple class to playback audio files.
/// Supports seeking within track and notifies delegate of play/pause/stop state changes
public class AudioPlayerEngine {
    
    //MARK: Member variables - private
    
    //AVAudioEngine and nodes
    internal var engine: AVAudioEngine = AVAudioEngine()
    internal var player: AVAudioPlayerNode = AVAudioPlayerNode()
    internal let mixer: AVAudioMixerNode = AVAudioMixerNode()
    
    //audio file
    internal var audioFile: AVAudioFile?
    
    //seek position for start
    private var seekPosition: AVAudioFramePosition = kTrackHeadFramePosition
    
    //indication of external interruption of playback
    private var interrupted: Bool = false
    
    //state tracking for AVAudioPlayerNode
    private var paused: Bool = false
    private var pausedPosition: TimeInterval = 0.0
    private var stopping: Bool = false
    private var reachedEnd: Bool = false

    //Buffer queue management and thread safety
    private let bufferQueue: DispatchQueue = DispatchQueue(label: "com.cyberdev.AudioPlayerEngine.buffers")
    private var buffersInFlight: Int = 0
    
    //MARK: - Member variables - public
    public weak var delegate: AudioPlayerDelegate?

    private(set) public var trackLength: TimeInterval = 0.0
    
    ///playback postion as percentage 0.0->1.0
    public var playbackProgress: Float {
        get {
            guard trackLength > 0.0 else {
                return 0.0
            }
            
            return Float(playbackPosition / trackLength).clamped(to: 0.0...1.0)
        }
        
        set (position) {
            let clamped = position.clamped(to: 0.0...1.0)
            let offsetSeconds: TimeInterval = trackLength * TimeInterval(clamped)
            playbackPosition = offsetSeconds
        }
    }

    //playback position in seconds
    public var playbackPosition: TimeInterval {
        get {
            //playing
            if let playerTime: AVAudioTime = currentPlayerTime() {
                return TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
            }
                
            //paused
            else if isPaused() {
                return pausedPosition
            }
            
            //stopped
            else if let audioFile = audioFile {
                return TimeInterval(Double(seekPosition) / audioFile.fileFormat.sampleRate)
            }
            
            //not configured
            return 0.0
        }
        
        set(seconds) {
            guard let audioFile = self.audioFile else {
                return
            }
            
            let newPosition = AVAudioFramePosition(seconds * audioFile.fileFormat.sampleRate)
            
            //if newPosition > audioFile.length then we are scheduling past end of file, allowing this for now as nothing bad happens
            
            let wasPlaying: Bool = self.isPlaying()
            if wasPlaying || isPaused() {
                _stop()
            }
            
            seekPosition = newPosition
            
            if wasPlaying {
                _play()
            }
        }
    }
        
    //MARK: Initialization
    
    public init() {
        initAudioEngine()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    ///Call this is to setup playback options for your app to allow simulataneous playback with other apps.
    /// This mode allows playback of audio when the ringer (mute) switch is enabled.
    /// Be sure to enable audio in the BackgroundModes settings of your apps Capabilities if necessary.
    #if os(iOS) || os(watchOS)
    public class func initAudioSessionCooperativePlayback() {
        try? AVAudioSession.sharedInstance().setActive(true)
        
        //AVAudioSessionCategoryMultiRoute - AVAudioSessionCategoryPlayback
        try? AVAudioSession.sharedInstance().setCategory(.playback,
                                                         mode: .default,
                                                         policy: .longFormAudio)
    }
    #endif
    
    internal func initAudioEngine() {
        //attach nodes
        engine.attach(player)
        engine.attach(mixer)
        
        //create node graph
        // note: use of mixer here allows for better abstraction
        //       of mapping channels in audio file to the output device
        engine.connect(player, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        
        engine.prepare()
        engine.isAutoShutdownEnabled = true
    }
    
    //ensure output format of player matches format of the file
    internal func matchFilePlaybackFormat(_ fileFormat: AVAudioFormat) {
        let mainsFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let playbackFormat = AVAudioFormat(commonFormat: mainsFormat.commonFormat,
                                           sampleRate: fileFormat.sampleRate,
                                           channels: fileFormat.channelCount,
                                           interleaved: mainsFormat.isInterleaved)
        
        engine.connect(player, to: mixer, format: playbackFormat)
        
        //prepare the engine
        engine.prepare()
    }

    //MARK: Public Methods
    @discardableResult public func setTrack(url: URL) -> Bool {
        guard let file: AVAudioFile = try? AVAudioFile.init(forReading: url) else {
            return false
        }
        
        //managing playback state
        let wasPlaying: Bool = isPlaying()
        if wasPlaying {
            _stop()
        }
        
        audioFile = file
        trackLength = Double(file.length)/file.processingFormat.sampleRate
        seekPosition = kTrackHeadFramePosition
                
        matchFilePlaybackFormat(file.fileFormat)
        
        registerForMediaServerNotifications()
        
        if wasPlaying {
            _play()
        }
        
        return true
    }
        
    public func isPlaying() -> Bool {
        bufferQueue.sync {
            player.isPlaying
        }
    }
    
    public func isPaused() -> Bool {
        bufferQueue.sync {
            paused
        }
    }
    
    @discardableResult public func play() -> Bool {
        let result: Bool
        
        if isPaused() {
            bufferQueue.sync {
                player.play()
                paused = false
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
    
    @discardableResult public func pause() -> Bool {
        guard isPlaying() else {
            return isPaused()
        }
        
        _pause()
        
        DispatchQueue.main.async {
            self.delegate?.playbackPaused()
        }
        
        return isPaused()
    }
    
    public func stop() {
        guard isPlaying() else {
            return
        }
                
        _stop()
        
        DispatchQueue.main.async {
            self.delegate?.playbackStopped(trackCompleted: self.reachedEnd)
        }
    }
        
    //MARK: Private Methods
    
    @discardableResult private func _play() -> Bool {
        guard !isPlaying() else {
            return true
        }
        
        //check we are configured to play something
        guard let trackToPlay = audioFile, startEngine() else {
            return false
        }
        
        //If a seek offset is set then move track head to that position
        if seekPosition != kTrackHeadFramePosition {
            trackToPlay.framePosition = seekPosition
            initBuffers()
            
            bufferQueue.sync {
                if let currentPos: AVAudioFramePosition = self.player.lastRenderTime?.sampleTime {
                    let playTime: AVAudioTime = AVAudioTime(sampleTime: currentPos-self.seekPosition,
                                                           atRate: trackToPlay.processingFormat.sampleRate)
                    self.player.play(at: playTime)
                }
            }
            
            //reset seek position now that it has been consumed
            seekPosition = kTrackHeadFramePosition
        }
            
            //otherwise just start playing at beginning of track
        else {
            //ensure file framePosition at head in case we are re-playing a track
            trackToPlay.framePosition = 0
            initBuffers()
            
            bufferQueue.sync {
                player.play()
            }
        }
        
        return isPlaying()
    }
    
    private func _pause() {
        let trackPosition = self.playbackPosition
        
        player.pause()
        
        bufferQueue.sync {
            paused = true
            pausedPosition = trackPosition
        }
    }
    
    private func _stop() {
        bufferQueue.sync {
            stopping = true
            paused = false
        }
        defer {
            bufferQueue.sync {
                stopping = false
            }
        }

        player.stop()

        stopEngine()
    }
    
    //MARK: Utility
    
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
        bufferQueue.sync {
            guard let nodeTime: AVAudioTime = player.lastRenderTime else {
                return nil
            }
            
            return player.playerTime(forNodeTime: nodeTime)
        }
    }
    
    //MARK: Audio buffer handling
    
    private func initBuffers() {
        guard let audioFile = audioFile else {
            return
        }
        
        reachedEnd = false
        
        for _ in 1...kMaxBuffersInFlight {
            guard let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: kBufferFrameCount) else {
                return
            }
            loadBuffer(buffer: buffer)
        }
    }
    
    @discardableResult private func loadBuffer(buffer: AVAudioPCMBuffer) -> Bool {
        bufferQueue.sync {
            //Fill buffer with samples/data from file
            guard readNextBuffer(buffer: buffer) else {
                return false
            }
            
            //track scheduled buffers
            buffersInFlight += 1
            
            //schedule buffer for playback at end of player queue
            // on completion reschedule with new data from file or exit
            player.scheduleBuffer(buffer) { () -> Void in
                var bufferQueueDrained = false
                var stopping = false
                
                self.bufferQueue.sync {
                    self.buffersInFlight -= 1
                    bufferQueueDrained = self.buffersInFlight == 0
                    stopping = self.stopping
                }
                
                //if in the process of stopping don't refill this buffer
                guard !stopping else {
                    return
                }
                
                //when buffer queue is drained we are done with playback
                // call stop for engine cleanup
                guard !bufferQueueDrained else {
                    DispatchQueue.main.async {
                        self.reachedEnd = true
                        self.stop()
                    }
                    return
                }
                
                //to understand recursion one must first understand recursion
                self.loadBuffer(buffer: buffer)
            }
            
            return true
        }
    }
    
    private func readNextBuffer(buffer: AVAudioPCMBuffer) -> Bool {
        guard let audioFile = audioFile, audioFile.framePosition < audioFile.length else {
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
    
    //MARK: Session notificaiton handling
    
    #if os(iOS) || os(watchOS)
    private func registerForMediaServerNotifications() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] (notification: Notification) in
            guard let why: AVAudioSession.InterruptionType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType else {
                return
            }
            
            switch why {
            case .began:
                self?.interruptSessionBegin()
            case .ended:
                self?.interruptSessionEnd()
            @unknown default:
                break;
            }
        }
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereLostNotification, object: nil, queue: nil) { /*[weak self]*/ (notification: Notification) in
            //TODO: Reset everything here
        }
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: nil) { /*[weak self]*/ (notification: Notification) in
            //TODO: Reset everything here
        }
    }
    #else
    private func registerForMediaServerNotifications() {
        //TODO:
    }
    #endif
    
    private func interruptSessionBegin() {
        guard let nodeTime: AVAudioTime = player.lastRenderTime,
            let playerTime: AVAudioTime = player.playerTime(forNodeTime: nodeTime) else {
                return
        }
        
        interrupted = true
        seekPosition = playerTime.sampleTime
        
        pause()
        
        engine.stop()
    }
    
    private func interruptSessionEnd() {
        if interrupted {
            play()
        }
    }
}

//MARK: - FXAudioPlayerEngine

//TimePitch Rate constants

public let kRateMin: Float = 0.03125
public let kRateCenter: Float = 1.0
public let kRateMax: Float = 32.0

//Track output level constants
fileprivate let kOutputLevelDefault: Float = 0.0

//Equalizer constants
fileprivate let kNumberOfBands: Int = 4
fileprivate let kLowShelfInitialFrequency: Float = 20.0
fileprivate let kParametricLowInitialFrequency: Float = 200.0
fileprivate let kParametricHighInitialFrequency: Float = 2000.0
fileprivate let kHighShelfInitialFrequency: Float = 20000.0
fileprivate let kEQGainDetentRange: Float = 0.5

///AudioPlayerEngine subclass that adds time rate control, four band parametric EQ, and simple output routing
public class FXAudioPlayerEngine: AudioPlayerEngine, AudioPlayer {
    //Associate with mediaItem, assumes mediaItem has assetURL
    public var mediaItem: MPMediaItem? = nil {
        didSet {
            guard let url = mediaItem?.assetURL else {
                return
            }
            asset = nil
            setTrack(url: url)
        }
    }
    
    public var asset: AVURLAsset? = nil {
        didSet {
            guard let asset = asset else {
                return
            }
            mediaItem = nil
            setTrack(url: asset.url)
        }
    }

    //Audio Units
    private let timePitch: AVAudioUnitTimePitch = AVAudioUnitTimePitch()
    private let equalizer: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: kNumberOfBands)
    private let routingMixer: AVAudioMixerNode = AVAudioMixerNode()
    
    //MARK: Member variables - public
    
    public var outputSampleRate: Double? {
        get {
            self.engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        }
    }
    
    public var hasOutputRouting: Bool {
        true
    }
    
    public var outputRouting: AudioPlayerOutputRouting? = .stereo {
        didSet {
            guard outputRouting != oldValue, let newRouting = outputRouting else {
                return
            }
                        
            guard let monoLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono) else {
                return
            }
            
            engine.disconnectNodeOutput(routingMixer)
            let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            let monoFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                           sampleRate: outputFormat.sampleRate,
                                           interleaved: outputFormat.isInterleaved,
                                           channelLayout: monoLayout)
            
            switch newRouting {
            case .stereo:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: outputFormat)
                routingMixer.pan = 0.0
                
            case .mono:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = 0.0
                
            case .monoLeft:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = -1.0
                
            case .monoRight:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = 1.0
            }
        }
    }
    
    public var hasOutputLevelAdjust: Bool {
        true
    }

    ///Adjust track playback level in range: -1.0 to 1.0
    public var trackOutputLevelAdjust: Float? {
        get {
            (engine.mainMixerNode.outputVolume.doubled) - 1.0
        }
        
        set (level) {
            let newLevel = level ?? kOutputLevelDefault
            engine.mainMixerNode.outputVolume = (newLevel + 1.0).halved
        }
    }
    
    public var timePitchQuality: AudioPlayerTimePitchQuality? = .med {
        didSet {
            timePitch.overlap = timePitchQuality?.rawValue ?? AudioPlayerTimePitchQuality.med.rawValue
        }
    }
    
    ///Adjust the time pitch rate in the range: 0.03125 to 32.0, default is 1.0
    public var playbackRate: Float {
        get {
            timePitch.rate
        }
        
        set(rate) {
            guard rate != timePitch.rate else {
                return
            }
            
            timePitch.rate = rate

            //Enabling bypass when at center position saves us significant CPU cycles, battery, etc.
            // I presume Apple doesn't do this by default in order better predict/reserve CPU cycles
            // necessary for audio processing. This optimization may need to be made conditional if
            // we hit similar issues.
            timePitch.bypass = (rate == kRateCenter)
            
            DispatchQueue.main.async {
                self.delegate?.playbackRateAdjusted()
            }
        }
    }
    
    ///Playback duration adjusted for playbackRate
    public var playbackDuration: TimeInterval {
        trackLength / TimeInterval(playbackRate)
    }
        
    public var hasEQSettings: Bool {
        true
    }

    ///Array of EQ filter parameters
    public var equalizerBands: [AudioPlayerEQFilterParameters] {
        get {
            equalizer.bands.map { AudioPlayerEQFilterParameters(filter: $0) }
        }
        
        set(bands) {
            for (index, band) in bands.enumerated() {
                setFilter(atIndex: index, filter: band)
            }
        }
    }
    
    //MARK: Init
    
    public init(mediaItem: MPMediaItem? = nil) {
        super.init()
        self.mediaItem = mediaItem
        if let url = self.mediaItem?.assetURL {
            setTrack(url: url)
        }
    }
    
    public init(asset: AVURLAsset? = nil) {
        super.init()
        self.asset = asset
        if let url = self.asset?.url {
            setTrack(url: url)
        }
    }

    override internal func initAudioEngine () {
        //super first so it will setup player, etc.
        super.initAudioEngine()
        
        //configure time pitch
        timePitch.bypass = false
        timePitch.overlap = timePitchQuality?.rawValue ?? AudioPlayerTimePitchQuality.med.rawValue
        engine.attach(timePitch)
        
        //configure eq
        equalizer.bypass = false
        equalizer.globalGain = 0.0
        engine.attach(equalizer)
        resetEQ()
        
        //configure mixer
        engine.attach(routingMixer)
        
        //construct fx node graph... connect to output of the playback mixer
        engine.connect(mixer, to: timePitch, format: nil)
        engine.connect(timePitch, to: equalizer, format: nil)
        engine.connect(equalizer, to: routingMixer, format: nil)
        engine.connect(routingMixer, to: engine.mainMixerNode, format: nil)
        
        //configure gain structure
        self.trackOutputLevelAdjust = kOutputLevelDefault
        
        //prepare the engine
        engine.prepare()
    }
        
    //MARK: Public Methods
    
    ///Reset EQ, track output level, and time pitch effect to nominal values.
    public func reset() {
        resetEQ()
        trackOutputLevelAdjust = kOutputLevelDefault
        playbackRate = kRateCenter
    }
    
    ///Reset EQ to nominal (flat) values
    public func resetEQ() {
        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = kLowShelfInitialFrequency
        equalizer.bands[0].gain = 0.0
        equalizer.bands[0].bypass = false
        
        equalizer.bands[1].filterType = .parametric
        equalizer.bands[1].bandwidth = 1.0
        equalizer.bands[1].frequency = kParametricLowInitialFrequency
        equalizer.bands[1].gain = 0.0
        equalizer.bands[1].bypass = false

        equalizer.bands[2].filterType = .parametric
        equalizer.bands[2].bandwidth = 1.0
        equalizer.bands[2].frequency = kParametricHighInitialFrequency
        equalizer.bands[2].gain = 0.0
        equalizer.bands[2].bypass = false

        equalizer.bands[3].filterType = .highShelf
        equalizer.bands[3].frequency = kHighShelfInitialFrequency
        equalizer.bands[3].gain = 0.0
        equalizer.bands[3].bypass = false
    }
    
    ///Adjust EQ filter at given index to given set of filter parameters
    public func setFilter(atIndex filterIndex: Int,
                          filter: AudioPlayerEQFilterParameters) {
        equalizer.bands[filterIndex].filterType = filter.filterType
        setFilter(atIndex: filterIndex,
                  frequency: filter.frequency,
                  gain: filter.gain,
                  bandwidth: filter.bandwidth)
    }
    
    ///Adjust EQ filter at given index to given set of filter parameters
    public func setFilter(atIndex filterIndex: Int,
                          frequency: Float,
                          gain: Float,
                          bandwidth: Float = 0.0) {
        equalizer.bands[filterIndex].frequency = frequency
        
        if abs(gain) <= kEQGainDetentRange {
            equalizer.bands[filterIndex].gain = 0.0
        } else {
            equalizer.bands[filterIndex].gain = gain
        }
        
        if bandwidth > 0.0 {
            equalizer.bands[filterIndex].bandwidth = bandwidth
        }
    }
}

//Required to make AVAudioUnitEQFilterType automagically codable
extension AVAudioUnitEQFilterType: Codable {
}

///Wrapup struct for persisting EQ settings... these map directly to AVAudioUnitEQFilterParameters which is not copyable/fungable
public struct AudioPlayerEQFilterParameters: Codable, Equatable {
    //Properties from AVAudioUnitEQFilterParameters
    public var filterType: AVAudioUnitEQFilterType
    public var frequency: Float
    public var bandwidth: Float
    public var gain: Float
    public var bypass: Bool
    
    public init(filter: AVAudioUnitEQFilterParameters) {
        self.filterType = filter.filterType
        self.frequency = filter.frequency
        self.bandwidth = filter.bandwidth
        self.gain = filter.gain
        self.bypass = filter.bypass
    }
}

//MARK: - MediaPlayer extension

import MediaPlayer

///Defines simplified audio routing options
public enum AudioPlayerOutputRouting {
    case stereo //stereo or mono source output to stereo device
    case mono //mono output (all channels combined) to both channels of stereo device
    case monoLeft //mono output (all channels combined) to left channel of stereo device
    case monoRight //mono output (all channels combined) to right channel of stereo device
}

///Defines simplified values for TimePitch overlap parameter which roughly
/// translates to quality, i.e. reduction in artifacts at the
/// expense of increased CPU overhead.
public enum AudioPlayerTimePitchQuality : Float {
    case low = 3.0
    case med = 8.0
    case high = 32.0
}

public struct PlaybackPosition {
    public let position: Float
    public let current: TimeInterval
    public let remaining: TimeInterval
    public let duration: TimeInterval
}

///Protocol for our concept of an audio player which abstracts MPMediaPlayer and AVAudioEngine/AVAudioPlayerNode
/// Not all features (EQ, routing, track output level) are supported by both so you need to check with your factory created object
/// after initialization to see what is available.
/// - note: The MPMediaPlayer concept of a queue is hidden here as well. The assumption is that you want
///         full controll over playback and thus assume full responsibility for transitions.
public protocol AudioPlayer: class {
    var delegate: AudioPlayerDelegate? { get set }
    
    var mediaItem: MPMediaItem? { get set }
    
    var asset: AVURLAsset? { get set }
    
    var assetURL: URL? {get }

    var playbackPosition: TimeInterval { get set }
    
    var playbackProgress: Float {get set}

    ///Playback duration adjusted for playbackRate
    var playbackDuration: TimeInterval { get }

    ///Adjust the time pitch rate in the range: 0.03125 to 32.0, default is 1.0
    var playbackRate: Float { get set }

    var currentPosition: PlaybackPosition { get }
    
    var hasOutputRouting: Bool { get }
    var outputRouting: AudioPlayerOutputRouting? { get set }

    var hasOutputLevelAdjust: Bool { get }
    ///Adjust track playback level in range: -1.0 to 1.0
    ///A detent around zero is automatically applied.
    ///
    ///- note: You may want to read back the value after setting to get actual value of the control.
    var trackOutputLevelAdjust: Float? { get set }

    var timePitchQuality: AudioPlayerTimePitchQuality? { get set }

    var hasEQSettings: Bool { get }

    ///Array of EQ filter parameters
    var equalizerBands: [AudioPlayerEQFilterParameters] { get set }
    
    var outputSampleRate: Double? { get }
    
    @discardableResult func play() -> Bool
    func isPlaying() -> Bool

    @discardableResult func pause() -> Bool
    func isPaused() -> Bool

    ///Toggle play/pause as appropriate
    @discardableResult func plause() -> Bool

    func stop()
    
    ///Adjust EQ filter at given index to given set of filter parameters
    func setFilter(atIndex filterIndex: Int, filter: AudioPlayerEQFilterParameters)

    ///Adjust EQ filter at given index to given set of filter parameters
    func setFilter(atIndex filterIndex: Int, frequency: Float, gain: Float, bandwidth: Float)
}

extension AudioPlayer {
    public var assetURL: URL? {
        get {
            if asset != nil {
                return asset?.url
            } else if mediaItem != nil {
                return mediaItem?.assetURL
            }
            
            return nil
        }
    }

    public var playbackDuration: TimeInterval {
        guard let duration = mediaItem?.playbackDuration else {
            return 0.0
        }
        return ceil(duration / TimeInterval(playbackRate))
    }
    
    public var currentPosition: PlaybackPosition {
        let progress = playbackProgress.clamped(to: 0.0...1.0)
        
        //time adjusted for changes in playback rate
        let duration = playbackDuration
        let current: TimeInterval = duration * Double(progress)
        let remaining: TimeInterval = duration - current
        
        return PlaybackPosition(position: progress,
                                current: current,
                                remaining: remaining,
                                duration: duration)
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

    ///playback postion as percentage 0.0->1.0
    public var playbackProgress: Float {
        get {
            guard let duration = mediaItem?.playbackDuration, duration > 0.0 else {
                return 0.0
            }
            
            return Float(playbackPosition/duration)
        }
        
        set(position) {
            guard let duration = mediaItem?.playbackDuration else {
                return
            }

            let clamped = position.clamped(to: 0.0...1.0)
            let offsetSeconds: TimeInterval = duration * TimeInterval(clamped)
            playbackPosition = offsetSeconds
        }
    }

    public var hasOutputRouting: Bool {
        false
    }
    public var outputRouting: AudioPlayerOutputRouting? {
        get { nil }
        set {}
    }
    
    public var hasOutputLevelAdjust: Bool {
        false
    }
    public var trackOutputLevelAdjust: Float? {
        get { nil }
        set {}
    }
    
    public var timePitchQuality: AudioPlayerTimePitchQuality? {
        get { nil }
        set {}
    }
    
    public var hasEQSettings: Bool {
        false
    }
    public var equalizerBands: [AudioPlayerEQFilterParameters] {
        get { [] }
        set {}
    }
    
    public var outputSampleRate: Double? {
        nil
    }
    
    public func setFilter(atIndex filterIndex: Int, filter: AudioPlayerEQFilterParameters) {
    }
    
    public func setFilter(atIndex filterIndex: Int, frequency: Float, gain: Float, bandwidth: Float) {
    }
}

///This is a thin wrapper on MPMusicPlayerController to give us interface consistency with AudioPlayer for factory construction
public class MusicPlayer: AudioPlayer {
    private var player: MPMusicPlayerController {
        didSet {
            setupPlayer()
        }
    }
    private var playbackBegun: Bool = false
    
    public weak var delegate: AudioPlayerDelegate?

    public var mediaItem: MPMediaItem? = nil {
        didSet {
            setupPlayer()
        }
    }
    
    public var asset: AVURLAsset? {
        get {
            return nil
        }
        
        set {
            assert(false, "AVURLAsset not supported on MusicPlayer class")
        }
    }
    
    public var assetURL: URL? {
        return mediaItem?.assetURL
    }

    public var playbackPosition: TimeInterval {
        get {
            player.currentPlaybackTime
        }
        set {
            player.currentPlaybackTime = newValue
        }
    }

    public var playbackRate: Float = 1.0 {
        didSet {
            //currentPlaybackRate == 0 when stopped
            guard player.currentPlaybackRate != 0,
                  player.currentPlaybackRate != playbackRate else {
                return
            }
            
            player.currentPlaybackRate = playbackRate
            DispatchQueue.main.async {
                self.delegate?.playbackRateAdjusted()
            }
        }
    }
    
    public init(mediaItem: MPMediaItem? = nil) {
        self.mediaItem = mediaItem
        player = MPMusicPlayerController.cleanApplicationMusicPlayer
        setupPlayer()

        NotificationCenter.default.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange,
                                               object: player,
                                               queue: .main)
        { [weak self] (notification) in
            DispatchQueue.main.async {
                guard let state = self?.player.playbackState else {
                    return
                }
                
                switch state {
                case .stopped:
                    //player sends state change for 'stopped' on queue creation so we
                    // have to track playback state for our intended usage of track completion
                    if let started = self?.playbackBegun, started {
                        //reset media item in queue to prepare for possible replay/repeat
                        self?.setupPlayer()
                        self?.playbackPosition = 0.0
                        self?.delegate?.playbackStopped(trackCompleted: true)
                    }
                case .playing:
                    self?.delegate?.playbackStarted()
                case .paused:
                    self?.delegate?.playbackPaused()
                case .interrupted:
                    self?.delegate?.playbackStopped(trackCompleted: false)
                case .seekingForward:
                    break
                case .seekingBackward:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        player.beginGeneratingPlaybackNotifications()
    }

    deinit {
        player.setQueue(with: MPMediaItemCollection(items: []))
        NotificationCenter.default.removeObserver(self)
        player.endGeneratingPlaybackNotifications()
    }
    
    @discardableResult public func play() -> Bool {
        //setting playback rate has side effect of starting playback
        player.currentPlaybackRate = playbackRate
        playbackBegun = true
        return isPlaying()
    }
    
    public func isPlaying() -> Bool {
        player.playbackState == .playing
    }
    
    @discardableResult public func pause() -> Bool {
        player.pause()
        return isPaused()
    }
    
    public func isPaused() -> Bool {
        player.playbackState == .paused
    }
        
    public func stop() {
        player.stop()
    }
    
    private func setupPlayer() {
        player.repeatMode = .none
        player.shuffleMode = .off

        if let id = mediaItem?.playbackStoreID {
            player.setQueue(with: [id])
            player.prepareToPlay() { error in
                guard let error = error else {
                    return
                }
                
                print("Error in MPMusicPlayerController.prepareToPlay: \(error)")
            }
        }
    }
}

///Factory creator for audio player classes
///
/// Not all features (EQ, routing, track output level) are supported by all types of players so you need to check with your factory created object
/// after initialization to see what is available.
public struct AudioPlayerFactory {
    ///Create an appropriate audio player based on the media item
    public static func createPlayer(for mediaItem: MPMediaItem) -> AudioPlayer {
        if mediaItem.assetURL != nil {
            return FXAudioPlayerEngine(mediaItem: mediaItem)
        }
        else {
            return MusicPlayer(mediaItem: mediaItem)
        }
    }
    
    public static func createPlayer(for asset: AVURLAsset) -> AudioPlayer {
        return FXAudioPlayerEngine(asset: asset)
    }
}


extension MPMusicPlayerController {
    class var cleanApplicationMusicPlayer: MPMusicPlayerController {
        let result = applicationMusicPlayer
        result.setQueue(with: [])
        result.currentPlaybackTime = 0.0
        return result
    }
}