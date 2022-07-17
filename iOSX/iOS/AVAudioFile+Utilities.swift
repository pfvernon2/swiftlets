//
//  AVAudioFile+Utilities.swift
//  swiftlets
//
//  Created by Frank Vernon on 7/16/20.
//  Copyright © 2020 Frank Vernon. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

public let kDefaultNoiseFloor: Float = -50.0
private let kProcessingFormat: AVAudioCommonFormat = .pcmFormatFloat32

//Utility accessors
public extension AVAudioFile {
    ///Length of file in seconds
    var duration: TimeInterval{
        time(forFrame: length)
    }
    
    ///Number of audio channels
    var channelCount: UInt32 {
        processingFormat.channelCount
    }
    
    ///Effective sample rate of file
    var sampleRate: Double {
        processingFormat.sampleRate
    }
    
    ///Utility to convert a frame position to seconds
    func time(forFrame frame: AVAudioFramePosition) -> TimeInterval {
        TimeInterval(Double(frame) / processingFormat.sampleRate)
    }
    
    ///Utility to convert time in seconds to a frame position
    func frame(forTime time: TimeInterval) -> AVAudioFramePosition {
        AVAudioFramePosition(time * processingFormat.sampleRate)
    }
    
    ///Utility to calculate the progress position of a frame. Returns percentage value between 0...1
    func progress(forFrame frame: AVAudioFramePosition) -> Float {
        frame.percentage(of: length).clamped(to: 0.0...1.0)
    }
}

//Utility functions
public extension AVAudioFile {
    ///Read entire file into buffer based on the processing format.
    ///
    /// - parameter asMono - pass true to retrieve mono version of samples. Useful for creating images, for example.
    func samples(asMono mono: Bool) throws -> AVAudioPCMBuffer {
        guard var buf = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: UInt32(length)) else {
            throw SwiftletsAudioFileError.outOfMemory
        }
        
        try read(into: buf)
        
        //TODO: Make this more efficient on memory by doing mono conversion during chunked file read
        if mono && processingFormat.channelCount > 1 {
            guard let monoFormat = AVAudioFormat(commonFormat: processingFormat.commonFormat,
                                                 sampleRate: processingFormat.sampleRate,
                                                 channels: 1,
                                                 interleaved: false) else {
                throw SwiftletsAudioFileError.invalidFormat
            }
            
            guard let monoBuf = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: buf.frameLength) else {
                throw SwiftletsAudioFileError.outOfMemory
            }
            
            guard let converter = AVAudioConverter(from: buf.format, to: monoBuf.format) else {
                throw SwiftletsAudioFileError.invalidConverter
            }
            
            converter.downmix = true
            try converter.convert(to: monoBuf, from: buf)
            
            buf = monoBuf
        }
        
        return buf
    }
    
    ///Locates frame positions of first and last samples in the file with non-zero values. These frame positions can be used
    ///as start/stop positions on playback to effectively trim silence without modifying the file contents.
    ///
    /// - returns: Tuple of AVAudioFramePositions representing the frame positions of the first and last
    ///            non-zero samples in the file.
    func silenceTrimPositions() -> (AVAudioFramePosition, AVAudioFramePosition) {
        // be nice, don't reset file position
        let startingFramePosition = framePosition
        framePosition = .zero
        defer {
            framePosition = startingFramePosition
        }
        
        //Create buffer to hold a few seconds of the file data
        let bufferSize = UInt32(sampleRate * 3.0)
        guard let buf = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: bufferSize) else {
            return (.zero, length)
        }
        
        do {
            var start: AVAudioFramePosition? = nil
            var end: AVAudioFramePosition? = nil
            
            //read from head of file until we find non-silence
            var framesRead: AVAudioFrameCount = .zero
            while framesRead < length {
                try read(into: buf)
                
                start = buf.silenceTrimPosition()
                if start != nil {
                    start! += AVAudioFramePosition(framesRead)
                    break
                }
                
                framesRead += buf.frameLength
            }
            
            //read from tail of file until we find non-silence
            framesRead = .zero
            while framesRead < length {
                framePosition = length - AVAudioFramePosition(framesRead) - AVAudioFramePosition(bufferSize)
                try read(into: buf)

                end = buf.silenceTrimPosition(fromTail: true)
                if end != nil {
                    end! = (length - AVAudioFramePosition(framesRead + buf.frameLength)) + end!
                    break
                }
                
                framesRead += buf.frameLength
            }
                        
            return (start ?? .zero, end ?? length)
        } catch {
            return (.zero, length)
        }
    }
}

//Waveform approximation
public extension AVAudioFile {
    enum SwiftletsAudioFileError: Error {
        case invalidFormat
        case outOfMemory
        case invalidConverter
    }
    
    convenience init(forViewing fileURL: URL) throws {
        try self.init(forReading: fileURL, commonFormat: kProcessingFormat, interleaved: false)
    }
    
    ///Render file as mono waveform image. There are many like it, this is mine.
    ///
    /// - note: Not good on memory. Entire file read into memory before converstion
    ///         to mono and subsequent decimation. Total memory allocation is
    ///         1.5x pcm data size of AVAudioFile.
    func waveFormImage(imageSize: CGSize,
                       graphColor: UIColor,
                       scaleToDisplay: Bool = true,
                       noiseFloor: Float = kDefaultNoiseFloor) -> UIImage? {
        //number of pixels required to draw each "sample"
        let lineWidth: CGFloat = 1.0
        let lineSpacing: CGFloat = 1.0
        let pixelsPerSample = lineWidth + lineSpacing
        
        //get mono version of buffer
        guard let buffer = try? self.samples(asMono: true) else {
            return nil
        }
         
        //convert buffer to positive amplitude in DB
        buffer.performTransform { channelData in
            let sampleCount = vDSP_Length(buffer.frameLength)
            vDSP_vabs(channelData, 1, channelData, 1, sampleCount);
            var zero: Float = 1.0;
            vDSP_vdbcon(channelData, 1, &zero, channelData, 1, sampleCount, 1);
        }
        
        //decimate samples to correleate with number of pixels in width of image
        // this optimizes for the number of points we have to draw
        let samplesPerPixel = Int(buffer.frameLength) / Int(imageSize.width/pixelsPerSample)
        buffer.decimateBy(samplesPerPixel)
        
        //Get decimated samples (there will only be a few hundred now.)
        guard var samples = buffer.floatChannelArray?[0] else {
            return nil
        }
        
        // clip at noise floor and
        // add back noisefloor to make values positive amplitude in db
        var flr: Float = noiseFloor
        var ceil: Float = .zero
        vDSP_vclip(samples, 1, &flr, &ceil, &samples, 1, vDSP_Length(samples.count));
        vDSP.add(abs(noiseFloor), samples, result: &samples)

        //convert to sound pressure (gives us a bit more vertical 'resolution')
        samples = samples.map { pow(10.0, $0/20.0) }

        //normalize samples to the height of the image so we fill the image as best we can
        let imageMaxHeight = floor(imageSize.height)
        let maxAmplitude = vDSP.maximum(samples)
        let normalization = Float(imageMaxHeight) / maxAmplitude
        vDSP.multiply(normalization, samples, result: &samples)
        
        //generate waveform
        return UIGraphicsImageContext(size: imageSize, opaque: false, scale:scaleToDisplay ? 0.0 : 1.0) { (context) in
            context.setAllowsAntialiasing(true)
            
            let center = imageMaxHeight.halved
            let path = UIBezierPath()
            for (index, sample) in samples.enumerated() {
                let offset = CGFloat(index)
                let amplitude: CGFloat = max(CGFloat(sample), 1.0)
                
                let x = offset * pixelsPerSample
                let y = center - amplitude.halved
                
                path.addVerticalLine(at: CGPoint(x: x, y: y), ofLength: amplitude)
            }
            path.close()
            
            path.lineWidth = lineWidth
            
            graphColor.setStroke()
            path.stroke()
        }
    }
}
