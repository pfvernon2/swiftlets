//
//  AudioPlayerEngine.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/18/15.
//  Copyright © 2015 Frank Vernon. All rights reserved.
//

import AVFoundation
import MediaPlayer

//MARK: - AudioPlayerDelegate

///Watcher protocol for the AudioPlayerEngine class. All methods guaranteed to be called on main thread.
public protocol AudioPlayerDelegate: AnyObject {
    func playbackStarted()
    func playbackPaused()
    func playbackStopped(trackCompleted: Bool)
    func playbackLengthAdjusted()
}

//MARK: - Constants

//internal indication track should begin at head
fileprivate let kTrackHeadFramePosition: AVAudioFramePosition = .zero

//MARK: - AudioPlayerEngine

///Simple class to playback audio files.
///
/// Supports seeking within track, output channel mapping, and trimming of playback. Includes delegate for play/pause/stop state changes.
/// It's primary intent is for music track playback rather than background sounds or effects.
public class AudioPlayerEngine {
    ///Enum for indicating at which end(s) of the audio file
    /// to detect and trim silence at playback.
    public enum trimPositions {
        case leading
        case trailing
        case both
    }
    
    //MARK: - Member variables - private
    
    //AVAudioEngine and nodes
    internal var engine: AVAudioEngine = AVAudioEngine()
    internal var player: AVAudioPlayerNode = AVAudioPlayerNode()
    internal let mixer: AVAudioMixerNode = AVAudioMixerNode()

    //Trim positions
    private var headPosition: AVAudioFramePosition = kTrackHeadFramePosition
    private var tailPosition: AVAudioFramePosition = kTrackHeadFramePosition

    //seek position
    private var seekPosition: AVAudioFramePosition = kTrackHeadFramePosition

    //indication of external interruption of playback
    private var interrupted: Bool = false
    
    //Queue for local state tracking of AVAudioPlayerNode
    private let stateQueue: DispatchQueue = DispatchQueue(label: "com.cyberdev.AudioPlayerEngine.state")

    //Tracks whether there is a segment scheduled on player… There can be only one.
    @AtomicAccessor private var playerScheduled: Bool
    
    //Frame position of pause, necessary as player does not return
    // position while paused.
    //
    // This is used also to indicated whether we are
    // paused as player has no explicit way to indicate said state.
    @AtomicAccessor private var pausePosition: AVAudioFramePosition

    //Tracks whether scheduled segment played up/through its expected ending frame
    @AtomicAccessor private var segmentCompleted: Bool

    //Tracks if we are in a seek operation, allows us to ignore early
    // completion callback of previously scheduled segment
    @AtomicAccessor private var inSeek: Bool

    //Meter queue management
    private let meterQueue: DispatchQueue = DispatchQueue(label: "com.cyberdev.AudioPlayerEngine.meters")
    private var _meterValues: [Float] = []
    public private(set) var meters: [Float] {
        get {
            meterQueue.sync {
                _meterValues
            }
        }
        set(value) {
            meterQueue.async() {
                self._meterValues = value
            }
        }
    }
    
    ///AVAudioTime representing number of frames played since last start()
    ///
    /// - note: This is not adjusted for start position in file. This is the underlying player time.
    private var currentPlayerTime: AVAudioTime? {
        guard let nodeTime: AVAudioTime = player.lastRenderTime else {
            return nil
        }
        
        return player.playerTime(forNodeTime: nodeTime)
    }
    
    //MARK: - Member variables - public

    ///Delegate for notification of state changes on the player
    public weak var delegate: AudioPlayerDelegate?

    ///Set to true to have tap installed on output for monitoring meter levels
    public var meteringEnabled: Bool = false

    //MARK: File Info
    
    ///Backing audio file
    public private(set) var audioFile: AVAudioFile?
    
    ///File duration in seconds
    public var fileDuration: TimeInterval {
        audioFile?.duration ?? .zero
    }
    
    ///File length of file in frames
    public var fileLength: AVAudioFramePosition {
        audioFile?.length ?? .zero
    }
    
    ///Count of channels in file
    public var fileChannelCount: UInt32 {
        audioFile?.channelCount ?? .zero
    }
    
    ///Processing sampleRate of file
    public var fileSampleRate: Double {
        audioFile?.sampleRate ?? .zero
    }
    
    //MARK: Track Timing and Positioning

    ///Frame position of begining of segment to be played.
    ///
    ///This either the begining of the file, a user defined head position, or user defined seek position.
    private var startPosition: AVAudioFramePosition {
        max(min(endPosition, seekPosition), headPosition)
    }
    
    ///Frame position of end of segment to be played
    ///
    ///This either the end of the file or a user defined tail position.
    private var endPosition: AVAudioFramePosition {
        min(fileLength, tailPosition)
    }
    
    ///Length of segment to be played in frames
    private var segmentLength: AVAudioFrameCount {
        AVAudioFrameCount(endPosition - startPosition)
    }
        
    ///Time for head position relative to absolute length of file in seconds
    public var headTime: TimeInterval {
        time(forFrame: headPosition)
    }

    ///Head position as percentage relative to absolute length of file
    public var headProgress: Float {
        progress(forFrame: headPosition)
    }

    ///Time for tail position relative to absolute length of file in seconds
    public var tailTime: TimeInterval {
        time(forFrame: tailPosition)
    }

    ///Tail position as percentage relative to absolute length of file
    public var tailProgress: Float {
        progress(forFrame: tailPosition)
    }
    
    ///Length of trimmed section to be played in frames
    public var trimmedLength: AVAudioFrameCount {
        let tail = tailPosition > .zero ? tailPosition : fileLength
        let head = headPosition

        return AVAudioFrameCount(tail - head)
    }
    
    ///Playback length in seconds adjusted for trim at head/tail
    public var trimmedPlaybackDuration: TimeInterval {
        time(forFrame: AVAudioFramePosition(trimmedLength))
    }
    
    ///Playback postion as percentage 0.0->1.0 relative to trim at head/tail
    public var trimmedPlaybackProgress: Float {
        let current = playbackPosition - headPosition
        return current.percentage(of: trimmedLength)
    }
    
    ///TimeInterval of current position relative to trim at head/tail
    public var trimmedPlaybackTime: TimeInterval {
        let current = playbackPosition - headPosition
        return time(forFrame: current)
    }

    ///Last rendered frame including offset from startPosition
    public var currentPlayerPosition: AVAudioFramePosition? {
        guard let current = currentPlayerTime?.sampleTime else {
            return nil
        }
        
        return current + startPosition
    }
    
    ///Current frame position of playback relative to absolute length of file
    ///
    ///Setting this value will reposition the playback position to the
    /// specified frame.
    public var playbackPosition: AVAudioFramePosition {
        get {
            //playing
            if isPlaying() {
                return currentPlayerPosition ?? .zero
            }
            
            //paused
            else if isPaused() {
                return pausePosition
            }
            
            //stopped
            else {
                return startPosition
            }
        }
        
        set(frame) {
            guard audioFile != nil else {
                return
            }
            
            let wasPlaying: Bool = self.isPlaying()
            if wasPlaying || isPaused() {
                inSeek = true
                
                if isPaused() {
                    //update pausePosition so that progress updates while paused
                    pausePosition = frame
                }

                player.stop()
            }
            
            seekPosition = frame
            
            if wasPlaying {
                _play()
            }
        }
    }

    ///TimeInterval of current position relative to absolute length of file
    public var playbackTime: TimeInterval {
        get {
            time(forFrame: playbackPosition)
        }
        
        set(seconds) {
            playbackPosition = frame(forTime: seconds)
        }
    }

    ///Playback postion as percentage 0.0->1.0 relative to absolute length of file
    public var playbackProgress: Float {
        get {
            progress(forFrame: playbackPosition)
        }
        
        set (position) {
            let clamped = position.clamped(to: 0.0...1.0)
            let framePosition = floor(Double(fileLength) * Double(clamped))
            playbackPosition = AVAudioFramePosition(framePosition)
        }
    }
    
    ///Indicates playback will begin at head
    public var playbackAtHead: Bool {
        playbackPosition == headPosition
    }
    
    //MARK: Initialization
    
   #if os(iOS) || os(watchOS)
    ///Call this is to setup playback options for your app to allow simulataneous playback with other apps.
    /// The default mode allows playback of audio when the ringer (mute) switch is enabled.
    /// Be sure to enable audio in the BackgroundModes settings of your apps Capabilities if necessary.
     public class func initAudioSessionCooperativePlayback(category: AVAudioSession.Category = .playback,
                                                          policy: AVAudioSession.RouteSharingPolicy = .longFormAudio) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(category,
                                                            mode: .default,
                                                            policy: policy,
                                                            options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            //Prevent interruptions from incoming calls - unless user has configured device
            // for fullscreen call notifications
            if #available(iOS 14.5, *) {
                try AVAudioSession.sharedInstance().setPrefersNoInterruptionsFromSystemAlerts(true)
            }
        } catch {
            debugPrint("failed to initialize audio session: \(error)")
        }
    }
    #endif
    
    public init() {
        //shared queue not available until init time
        _playerScheduled = AtomicAccessor(wrappedValue: false, queue: stateQueue)
        _pausePosition = AtomicAccessor(wrappedValue: kTrackHeadFramePosition, queue: stateQueue)
        _segmentCompleted = AtomicAccessor(wrappedValue: false, queue: stateQueue)
        _inSeek = AtomicAccessor(wrappedValue: false, queue: stateQueue)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        meteringEnabled = false
        engine.stop()
    }
    
    //MARK: Public Methods
    @discardableResult public func setTrack(url: URL) -> Bool {
        guard let file = try? AVAudioFile.init(forReading: url) else {
            return false
        }
        
        setAudioFile(file)
        
        return true
    }
    
    public func setAudioFile(_ file: AVAudioFile) {
        //managing playback state
        let wasPlaying: Bool = isPlaying()
        if wasPlaying {
            _stop()
        } else {
            _reset()
        }
        
        audioFile = file
        headPosition = kTrackHeadFramePosition
        tailPosition = file.length
                
        initAudioEngine()
        
        if wasPlaying {
            _play()
        }
    }
    
    ///This is a temporary? hack to release the avaudioengine which appears
    ///to have a retain cycle issue. This must be called after play has been called on the object or
    ///avaudioengine will retain this object indefinitetly.
    public func shutdown() {
        DispatchQueue.main.async {
            self.stop()
            self.deinitAudioEngine()
        }
    }
        
    ///Set outputs for the engine
    public func mapOutputs(to channels: [AVAudioOutputNode.OutputChannelMapping]) {
        engine.outputNode.mapRouteOutputs(to: channels)
    }
    
    public func time(forFrame frame: AVAudioFramePosition) -> TimeInterval {
        audioFile?.time(forFrame: frame) ?? .zero
    }
    
    public func frame(forTime time: TimeInterval) -> AVAudioFramePosition {
        audioFile?.frame(forTime: time) ?? .zero
    }
    
    public func progress(forFrame frame: AVAudioFramePosition) -> Float {
        audioFile?.progress(forFrame: frame) ?? .zero
    }
        
    public func isPlaying() -> Bool {
        player.isPlaying
    }
    
    public func isPaused() -> Bool {
        pausePosition != kTrackHeadFramePosition
    }
    
    public func play() {
        _play()
        
        DispatchQueue.main.async {
            self.delegate?.playbackStarted()
        }
    }
    
    public func pause() {
        guard isPlaying() else {
            return
        }
        
        _pause()
        
        DispatchQueue.main.async {
            self.delegate?.playbackPaused()
        }
    }
    
    public func resume() {
        guard isPaused(), playerScheduled else {
            return
        }
        
        //edge case where OS interruption may disable
        // the engine on us.
        guard engine.isRunning else {
            stop()
            return
        }
        
        pausePosition = kTrackHeadFramePosition
        player.play()
    }

    ///Toggle play/pause as appropriate
    public func plause() {
        if isPlaying() {
            pause()
        } else {
            play()
        }
    }

    public func stop() {
        assert(Thread.isMainThread)
        
        let wasPlaying = isPlaying()
        let atEnd = segmentCompleted
        
        //player.stop() is particular about being called from main
        player.stop()

        _stop()
        
        if wasPlaying {
            delegate?.playbackStopped(trackCompleted: atEnd)
        }
    }
    
    ///Set headPosition and/or tailPosition by scanning audio file for silence (zero value samples)
    ///from specified position(s) in the file.
    ///
    /// - note: This is slightly expensive as it has to open the audio file and read
    /// from the specified ends of the file for zero value samples.
    public func trimSilence(_ trim: trimPositions = .both) {
        guard let (head, tail) = audioFile?.silenceTrimPositions() else {
            return
        }
        
        switch trim {
        case .leading:
            setTrimPositions(head: head)
        case .trailing:
            setTrimPositions(tail: tail)
        case .both:
            setTrimPositions(head: head, tail: tail)
        }
    }
    
    ///Trim start/end times.
    public func setTrimPositions(head: AVAudioFramePosition? = nil,
                                 tail: AVAudioFramePosition? = nil) {
        if let head = head {
            headPosition = head
        }
        
        if let tail = tail {
            tailPosition = tail
        }
        
        DispatchQueue.main.async {
            self.delegate?.playbackLengthAdjusted()
        }
    }
        
    //MARK: Private Methods
    
    internal func initAudioEngine() {
        deinitAudioEngine()
        
        engine.connect(engine.mainMixerNode,
                       to: engine.outputNode,
                       format: engine.outputNode.outputFormat(forBus: 0))

        //attach nodes
        engine.attach(player)
        engine.attach(mixer)
        
        let format = audioFile?.processingFormat
        
        //connect nodes
        // IMPORTANT: The mixer is used to abstract away
        // file format (channel count, sample rate) config from
        // other processing nodes which may want to connect to this stream.
        // Subclasses can connect to the mixer which is configured for file format.
        engine.connect(player, to: mixer, format: format)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        engine.prepare()
    }
    
    internal func deinitAudioEngine() {
        engine.stop()

        engine = AVAudioEngine()
    }
        
    @discardableResult private func _play() -> Bool {
        //check not currently playing
        guard !isPlaying() else {
            return true
        }
        
        //check paused but player running
        guard !(isPaused() && playerScheduled) else {
            resume()
            return isPlaying()
        }

        //check we are configured to play something
        guard let audioFile = audioFile, startEngine() else {
            return false
        }

        let endFrame = startPosition + AVAudioFramePosition(segmentLength)
        
        player.scheduleSegment(audioFile,
                               startingFrame: startPosition,
                               frameCount: segmentLength,
                               at: nil,
                               completionCallbackType: .dataPlayedBack) { state in
            self.playerScheduled = false
            
            guard !self.inSeek else {
                self.inSeek = false
                return
            }
            
            DispatchQueue.main.async {
                self.segmentCompleted = self.currentPlayerPosition ?? .zero >= endFrame
                self.stop()
            }
        }
        playerScheduled = true

        player.play()

        _meter()
        
        return isPlaying()
    }
    
    private func _pause() {
        pausePosition = playbackPosition
        player.pause()
    }
    
    private func _stop() {
        stopEngine()
        _reset()
    }
    
    private func _reset() {
        seekPosition = kTrackHeadFramePosition
        pausePosition = kTrackHeadFramePosition
        interrupted = false
        segmentCompleted = false
    }
    
    private func _meter() {
        //for some reason this seems necessary to avoid random crashes
        // when installing tap for the first time
        engine.mainMixerNode.removeTap(onBus: 0)
        meters = []

        if meteringEnabled {
            let format = engine.mainMixerNode.outputFormat(forBus: 0)
            engine.mainMixerNode.installTap(
              onBus: 0,
              bufferSize: 1024,
              format: format
            ) { buffer, _ in
                if let meters = buffer.rmsPowerValues() {
                    self.meters = meters
                }
            }
        }
    }
    
    //MARK: Utility
    
    @discardableResult private func startEngine() -> Bool {
        guard !engine.isRunning else {
            return true
        }
        
        do {
            try engine.start()
            registerForMediaServerNotifications()
        } catch let error as NSError {
            print("Exception in audio engine start: \(error.localizedDescription)")
        }
        
        return engine.isRunning
    }
    
    @discardableResult private func stopEngine() -> Bool {
        guard engine.isRunning else {
            return false
        }
        
        deregisterForMediaServerNotifications()
        engine.stop()
        
        return !engine.isRunning
    }
    
    //MARK: Session notificaiton handling
    
    #if os(iOS) || os(watchOS)
    private func registerForMediaServerNotifications() {
        deregisterForMediaServerNotifications()
                
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance(),
                                               queue: nil) { [weak self] (notification: Notification) in
            guard let userInfo = notification.userInfo,
                  let interruption = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: interruption) else {
                return
            }

            switch type {
            case .began:
                self?.interruptSessionBegin()
                
            case .ended:
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
                }
                
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                self?.interruptSessionEnd(resume: options.contains(.shouldResume))
                
            @unknown default:
                break;
            }
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                               object: AVAudioSession.sharedInstance(),
                                               queue: nil) { [weak self] (notification: Notification) in
            self?.stop()
        }
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification,
                                               object: AVAudioSession.sharedInstance(),
                                               queue: nil) { /*[weak self]*/ (notification: Notification) in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                      return
            }

            switch reason {
            case .newDeviceAvailable:
                if AVAudioSession.sharedInstance().currentRoute.hasHeadphonens {
                }

            case .oldDeviceUnavailable:
                if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
                   !previousRoute.hasHeadphonens {
                }

            default:
                break
            }
        }
    }
    
    func deregisterForMediaServerNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
                                                  object: AVAudioSession.sharedInstance())
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.mediaServicesWereResetNotification,
                                                  object: AVAudioSession.sharedInstance())
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.routeChangeNotification,
                                                  object: AVAudioSession.sharedInstance())
    }
    
    #else
    private func registerForMediaServerNotifications() {
        //TODO: Support media state notifications for non-iOS platforms
    }
    #endif
    
    private func interruptSessionBegin() {
        guard player.isPlaying else {
            return
        }
        
        interrupted = true
        
        pause()
    }
    
    private func interruptSessionEnd(resume: Bool) {
        guard interrupted && resume else {
            return
        }
        
        if !engine.isRunning {
            startEngine()
        }
        
        self.resume()
    }
    
    public var debugDescription: String {
        var outputDescriptions: [String] = []
        for bus in 0..<engine.outputNode.numberOfOutputs {
            let name = engine.outputNode.name(forOutputBus: bus)
            let format = engine.outputNode.outputFormat(forBus: bus)
            let desc = format.settings.map { "\($0) = \($1)" }.sorted()
            let channelMap = engine.outputNode.auAudioUnit.channelMap?.debugDescription
            
            outputDescriptions.append("Output \(bus):\nname = \(String(describing: name))\nChannelMap = \(String(describing: channelMap))\n\(desc.joined(separator: "\n"))")
        }
        
        return outputDescriptions.joined(separator: "\n")
    }
}

//MARK: - FXAudioPlayerEngine

//Track output level constants
fileprivate let kOutputLevelDefault: Float = .zero

//Equalizer constants
fileprivate let kEQNumberOfBands: Int = 4
fileprivate let kEQLowShelfInitialFrequency: Float = 20.0
fileprivate let kEQParametricLowInitialFrequency: Float = 200.0
fileprivate let kEQParametricHighInitialFrequency: Float = 2000.0
fileprivate let kEQHighShelfInitialFrequency: Float = 20000.0
fileprivate let kEQGainDetentRange: Float = 0.5

///AudioPlayerEngine subclass that adds time rate control, four band parametric EQ, and simple output routing
public class FXAudioPlayerEngine: AudioPlayerEngine {
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
    private let equalizer: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: kEQNumberOfBands)
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
                routingMixer.pan = .zero
                
            case .mono:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = .zero
                
            case .monoLeft:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = -1.0
                
            case .monoRight:
                engine.connect(routingMixer, to: engine.mainMixerNode, format: monoFormat)
                routingMixer.pan = 1.0
            }
        }
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
    
    public var timePitchQuality: AVAudioUnitTimePitch.QualityRange? = .high {
        didSet {
            timePitch.overlap = timePitchQuality?.rawValue ?? AVAudioUnitTimePitch.QualityRange.high.rawValue
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
            
            timePitch.rate = rate.clamped(to: AVAudioUnitTimePitch.RateRange.range)

            //Enabling bypass when at center position saves us significant CPU cycles, battery, etc.
            // I presume Apple doesn't do this by default in order better predict/reserve CPU cycles
            // necessary for audio processing. This optimization may need to be made conditional if
            // we hit similar issues.
            timePitch.bypass = (rate == AVAudioUnitTimePitch.RateRange.center.rawValue)
            
            DispatchQueue.main.async {
                self.delegate?.playbackLengthAdjusted()
            }
        }
    }
    
    ///Playback duration of playable segment adjusted for playbackRate
    public var adjustedPlaybackDuration: TimeInterval {
        trimmedPlaybackDuration / TimeInterval(playbackRate)
    }
    
    ///Playback time adjusted for playbackRate and head position
    public var adjustedPlaybackTime: TimeInterval {
        ((playbackTime  - headTime) / TimeInterval(playbackRate))
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

    override internal func initAudioEngine() {
        //super first so it will setup player, etc.
        super.initAudioEngine()
        
        let format = audioFile?.processingFormat

        //configure time pitch
        timePitch.bypass = false
        timePitch.overlap = timePitchQuality?.rawValue ?? AVAudioUnitTimePitch.QualityRange.high.rawValue
        engine.attach(timePitch)
        
        //configure eq
        equalizer.bypass = false
        equalizer.globalGain = .zero
        engine.attach(equalizer)
        resetEQ()
        
        //configure mixer
        engine.attach(routingMixer)
        
        //construct fx node graph... connect to output of the playback mixer
        engine.connect(mixer, to: timePitch, format: format)
        engine.connect(timePitch, to: equalizer, format: format)
        engine.connect(equalizer, to: routingMixer, format: format)
        engine.connect(routingMixer, to: engine.mainMixerNode, format: format)
        
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
        playbackRate = AVAudioUnitTimePitch.RateRange.center.rawValue
    }
    
    ///Reset EQ to nominal (flat) values
    public func resetEQ() {
        equalizer.bands[0].filterType = .lowShelf
        equalizer.bands[0].frequency = kEQLowShelfInitialFrequency
        equalizer.bands[0].gain = .zero
        equalizer.bands[0].bypass = false
        
        equalizer.bands[1].filterType = .parametric
        equalizer.bands[1].bandwidth = 1.0
        equalizer.bands[1].frequency = kEQParametricLowInitialFrequency
        equalizer.bands[1].gain = .zero
        equalizer.bands[1].bypass = false

        equalizer.bands[2].filterType = .parametric
        equalizer.bands[2].bandwidth = 1.0
        equalizer.bands[2].frequency = kEQParametricHighInitialFrequency
        equalizer.bands[2].gain = .zero
        equalizer.bands[2].bypass = false

        equalizer.bands[3].filterType = .highShelf
        equalizer.bands[3].frequency = kEQHighShelfInitialFrequency
        equalizer.bands[3].gain = .zero
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
                          bandwidth: Float = .zero) {
        equalizer.bands[filterIndex].frequency = frequency
        
        if abs(gain) <= kEQGainDetentRange {
            equalizer.bands[filterIndex].gain = .zero
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

///Defines simplified audio routing options
public enum AudioPlayerOutputRouting {
    case stereo //stereo or mono source output to stereo device
    case mono //mono output (all channels combined) to both channels of stereo device
    case monoLeft //mono output (all channels combined) to left channel of stereo device
    case monoRight //mono output (all channels combined) to right channel of stereo device
}

// MARK: - SystemVolumeMonitor

public extension NSNotification.Name {
    static let SystemVolumeMonitor: NSNotification.Name = NSNotification.Name("com.cyberdev.SystemVolumeMonitor")
}

//KVO appears to be only way to do this, so here we are.
public class SystemVolumeMonitor: NSObject {
    public class func sharedInstance() -> SystemVolumeMonitor {
        return _sharedInstance
    }

    private static let _sharedInstance = {
        SystemVolumeMonitor()
    }()

    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }

    public override init() {
        super.init()
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        AVAudioSession.sharedInstance().addObserver(self,
                                                    forKeyPath: Observation.VolumeKey,
                                                    options: [.initial, .new],
                                                    context: &Observation.Context)
    }
    
    public func stop() {
        AVAudioSession.sharedInstance().removeObserver(self,
                                                       forKeyPath: Observation.VolumeKey,
                                                       context: &Observation.Context)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &Observation.Context {
            if keyPath == Observation.VolumeKey,
               let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue {
                NotificationCenter.default.post(name: .SystemVolumeMonitor, userInfo: ["volume": volume])
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

//MARK: - AVAudioUnitTimePitch

public extension AVAudioUnitTimePitch {
    enum RateRange: Float {
        case min = 0.03125
        case center = 1.0
        case max = 32.0
        
        public static var range: ClosedRange<Float> {
            AVAudioUnitTimePitch.RateRange.min.rawValue...AVAudioUnitTimePitch.RateRange.max.rawValue
        }
    }
    
    enum PitchRange: Float {
        case min = -2400.0
        case center = 0.0
        case max = 2400.0
        
        public static var range: ClosedRange<Float> {
            AVAudioUnitTimePitch.PitchRange.min.rawValue...AVAudioUnitTimePitch.PitchRange.max.rawValue
        }
    }

    enum QualityRange: Float {
        case low = 3.0
        case med = 8.0
        case high = 32.0
        
        public static var range: ClosedRange<Float> {
            AVAudioUnitTimePitch.QualityRange.low.rawValue...AVAudioUnitTimePitch.QualityRange.high.rawValue
        }
    }
    
    static func rateToPercent(_ rate: Float) -> Float {
        (rate * 100.0) - 100.0
    }
    
    static func percentToRate(_ percent: Float) -> Float {
        RateRange.center.rawValue + (percent/100.0)
    }
    
    ///rate adjustment as percentage, zero based as signed whole numbers
    /// 1x speed = +0%
    /// 2x speed = +100%
    /// 1/2 speed = -50%
    var rateAsPercent: Float {
        get {
            AVAudioUnitTimePitch.rateToPercent(rate)
        }
        set(value) {
            rate = AVAudioUnitTimePitch.percentToRate(value)
        }
    }
}


// MARK: - AVAudioSessionRouteDescription

extension AVAudioSessionRouteDescription {
    var hasHeadphonens: Bool {
        outputs.filter({$0.portType == .headphones}).isNotEmpty
    }
}
